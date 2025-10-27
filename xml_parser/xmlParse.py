import xml.etree.ElementTree as ET
from dataclasses import dataclass
from typing import List, Dict, Set, Tuple, Optional
from collections import defaultdict
import json
from pathlib import Path
import os


@dataclass
class Annotation:
    """Represents a single annotation from EAF file"""
    tier: str
    value: str
    start_time: int
    end_time: int
    duration: int
    annotation_id: str
    parent_id: Optional[str] = None


@dataclass
class TaskHierarchy:
    """Represents the hierarchical structure of a task"""
    task_name: str
    subtasks: Dict[str, List[str]]  # subtask -> list of components
    
    
@dataclass
class ActionSequence:
    """Represents a sequence of actions performed by one OT"""
    ot_id: str
    task_name: str
    video_file: str
    task_annotations: List[Annotation]
    subtask_annotations: List[Annotation]
    component_annotations: List[Annotation]
    total_duration: int


class EAFParser:
    """Parser for ELAN Annotation Format (EAF) files"""
    
    def __init__(self, eaf_file: str):
        self.tree = ET.parse(eaf_file)
        self.root = self.tree.getroot()
        self.time_slots = self._parse_time_slots()
        
    def _parse_time_slots(self) -> Dict[str, int]:
        """Extract time slot ID to time value mapping"""
        time_order = self.root.find('TIME_ORDER')
        time_slots = {}
        
        for time_slot in time_order.findall('TIME_SLOT'):
            slot_id = time_slot.get('TIME_SLOT_ID')
            time_value = int(time_slot.get('TIME_VALUE'))
            time_slots[slot_id] = time_value
            
        return time_slots
    
    def _get_time_from_slot(self, slot_ref: str) -> int:
        """Convert time slot reference to actual time in milliseconds"""
        return self.time_slots.get(slot_ref, 0)
    
    def parse_annotations(self) -> List[Annotation]:
        """Extract all annotations from the EAF file"""
        annotations = []
        
        for tier in self.root.findall('TIER'):
            tier_id = tier.get('TIER_ID')
            parent_ref = tier.get('PARENT_REF')
            
            for ann in tier.findall('.//ALIGNABLE_ANNOTATION'):
                ann_id = ann.get('ANNOTATION_ID')
                start_ref = ann.get('TIME_SLOT_REF1')
                end_ref = ann.get('TIME_SLOT_REF2')
                value = ann.find('ANNOTATION_VALUE').text
                
                start_time = self._get_time_from_slot(start_ref)
                end_time = self._get_time_from_slot(end_ref)
                
                annotations.append(Annotation(
                    tier=tier_id,
                    value=value,
                    start_time=start_time,
                    end_time=end_time,
                    duration=end_time - start_time,
                    annotation_id=ann_id,
                    parent_id=parent_ref
                ))
        
        return annotations
    
    def get_video_file(self) -> str:
        """Extract the video filename from the EAF header"""
        media_desc = self.root.find('.//MEDIA_DESCRIPTOR')
        if media_desc is not None:
            media_url = media_desc.get('RELATIVE_MEDIA_URL', '')
            return Path(media_url).name
        return ""
    
    def get_participant_id(self) -> str:
        """Extract the participant/OT ID from tiers"""
        for tier in self.root.findall('TIER'):
            participant = tier.get('PARTICIPANT')
            if participant:
                return participant
        return "Unknown"


class TaskEncodingParser:
    """Parser for the task encoding hierarchy file (Excel format)"""
    
    
    def __init__(self, encoding_file: str):
        import openpyxl
        self.workbook = openpyxl.load_workbook(encoding_file)
        self.sheet = self.workbook["Sheet1"]  # explicitly pick Sheet1

    def parse_hierarchy(self) -> Dict[str, TaskHierarchy]:
        hierarchies = {}
        current_task = None
        current_subtask = None

        for i, row in enumerate(self.sheet.iter_rows(min_row=2, values_only=True)):
            values = list(row) + [None] * 4
            task, subtask, component = values[1], values[2], values[3]

            # Skip blank rows
            if not task and not current_task:
                continue

            if task:  # new task
                current_task = task
                current_subtask = None
                if current_task not in hierarchies:
                    hierarchies[current_task] = TaskHierarchy(task_name=current_task, subtasks={})

            if subtask:
                current_subtask = subtask
                hierarchies[current_task].subtasks.setdefault(current_subtask, [])

            if component and current_subtask:
                hierarchies[current_task].subtasks[current_subtask].append(component)

        return hierarchies


class ActionVocabularyBuilder:
    """Build comprehensive action vocabulary across all OTs"""
    
    def __init__(self):
        self.actions = defaultdict(int)  # action -> frequency
        self.task_actions = defaultdict(set)  # task -> set of actions
        self.action_contexts = defaultdict(list)  # action -> list of (task, subtask, tier)
        
    def add_annotations(self, task_name: str, annotations: List[Annotation]):
        """Add annotations from one video to the vocabulary"""
        for ann in annotations:
            self.actions[ann.value] += 1
            self.task_actions[task_name].add(ann.value)
            self.action_contexts[ann.value].append((
                task_name,
                ann.tier,
                ann.start_time,
                ann.duration
            ))
    
    def get_vocabulary_stats(self) -> Dict:
        """Get statistics about the action vocabulary"""
        return {
            'total_unique_actions': len(self.actions),
            'total_action_occurrences': sum(self.actions.values()),
            'actions_by_frequency': sorted(
                self.actions.items(), 
                key=lambda x: x[1], 
                reverse=True
            ),
            'tasks_coverage': {
                task: len(actions) 
                for task, actions in self.task_actions.items()
            }
        }
    
    def categorize_actions(self) -> Dict[str, List[str]]:
        """Categorize actions by type based on naming patterns"""
        categories = {
            'orient': [],
            'adjust': [],
            'thread': [],
            'pull': [],
            'roll': [],
            'lift': [],
            'lower': [],
            'lean': [],
            'unsleeve': [],
            'other': []
        }
        
        for action in self.actions.keys():
            action_lower = action.lower()
            categorized = False
            
            for category in categories.keys():
                if category != 'other' and category in action_lower:
                    categories[category].append(action)
                    categorized = True
                    break
            
            if not categorized:
                categories['other'].append(action)
        
        return categories


class Stage1Pipeline:
    """Main pipeline for Stage 1: Parse & Extract"""
    
    def __init__(self, encoding_file: str):
        self.encoding_parser = TaskEncodingParser(encoding_file)
        self.task_hierarchies = self.encoding_parser.parse_hierarchy()
        self.vocabulary_builder = ActionVocabularyBuilder()
        self.action_sequences = []
        
    def process_eaf_file(self, eaf_file: str) -> ActionSequence:
        """Process a single EAF file"""
        parser = EAFParser(eaf_file)
        annotations = parser.parse_annotations()
        
        # Separate annotations by tier
        task_anns = [a for a in annotations if a.tier == 'Task']
        subtask_anns = [a for a in annotations if a.tier == 'Subtask']
        component_anns = [a for a in annotations if a.tier == 'subtask_Component']
        
        # Get metadata
        ot_id = parser.get_participant_id()
        video_file = parser.get_video_file()
        task_name = task_anns[0].value if task_anns else "Unknown"
        
        # Calculate total duration
        total_duration = max([a.end_time for a in annotations]) if annotations else 0
        
        # Add to vocabulary
        self.vocabulary_builder.add_annotations(task_name, annotations)
        
        sequence = ActionSequence(
            ot_id=ot_id,
            task_name=task_name,
            video_file=video_file,
            task_annotations=task_anns,
            subtask_annotations=subtask_anns,
            component_annotations=component_anns,
            total_duration=total_duration
        )
        
        self.action_sequences.append(sequence)
        return sequence
    
    def process_directory(self, eaf_directory: str):
        """Process all EAF files in a directory"""
        for dirpath, dirnames, filenames in os.walk(eaf_directory):
            print(dirpath, dirnames, filenames)
            eaf_files = Path(dirpath).glob('*.eaf')
            
            for eaf_file in eaf_files:
                try:
                    print(f"Processing: {eaf_file.name}")
                    self.process_eaf_file(str(eaf_file))
                except Exception as e:
                    print(f"Error processing {eaf_file.name}: {e}")
    
    def export_results(self, output_dir: str):
        """Export all extracted data to JSON files"""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        # Export task hierarchies
        hierarchies_data = {
            name: {
                'task_name': h.task_name,
                'subtasks': h.subtasks
            }
            for name, h in self.task_hierarchies.items()
        }
        
        with open(output_path / 'task_hierarchies.json', 'w') as f:
            json.dump(hierarchies_data, f, indent=2)
        
        # Export action sequences
        sequences_data = []
        for seq in self.action_sequences:
            sequences_data.append({
                'ot_id': seq.ot_id,
                'task_name': seq.task_name,
                'video_file': seq.video_file,
                'total_duration': seq.total_duration,
                'num_subtasks': len(seq.subtask_annotations),
                'num_components': len(seq.component_annotations),
                'subtasks': [
                    {
                        'value': a.value,
                        'start': a.start_time,
                        'end': a.end_time,
                        'duration': a.duration
                    }
                    for a in seq.subtask_annotations
                ],
                'components': [
                    {
                        'value': a.value,
                        'start': a.start_time,
                        'end': a.end_time,
                        'duration': a.duration
                    }
                    for a in seq.component_annotations
                ]
            })
        
        with open(output_path / 'action_sequences.json', 'w') as f:
            json.dump(sequences_data, f, indent=2)
        
        # Export vocabulary statistics
        vocab_stats = self.vocabulary_builder.get_vocabulary_stats()
        with open(output_path / 'vocabulary_stats.json', 'w') as f:
            json.dump(vocab_stats, f, indent=2)
        
        # Export categorized actions
        categorized = self.vocabulary_builder.categorize_actions()
        with open(output_path / 'action_categories.json', 'w') as f:
            json.dump(categorized, f, indent=2)
        
        print(f"\n✓ Exported results to {output_path}")
        print(f"  - Task hierarchies: {len(self.task_hierarchies)} tasks")
        print(f"  - Action sequences: {len(self.action_sequences)} videos")
        print(f"  - Unique actions: {vocab_stats['total_unique_actions']}")
        print(f"  - Total occurrences: {vocab_stats['total_action_occurrences']}")
    
    def print_summary(self):
        """Print a summary of extracted data"""
        print("\n" + "="*60)
        print("STAGE 1: PARSE & EXTRACT - SUMMARY")
        print("="*60)
        
        print(f"\n📋 Task Hierarchies: {len(self.task_hierarchies)}")
        for task_name, hierarchy in list(self.task_hierarchies.items())[:3]:
            print(f"  • {task_name}: {len(hierarchy.subtasks)} subtasks")
        
        print(f"\n🎥 Action Sequences: {len(self.action_sequences)}")
        ot_counts = defaultdict(int)
        task_counts = defaultdict(int)
        for seq in self.action_sequences:
            ot_counts[seq.ot_id] += 1
            task_counts[seq.task_name] += 1
        
        print(f"  • Unique OTs: {len(ot_counts)}")
        print(f"  • Unique tasks: {len(task_counts)}")
        
        vocab_stats = self.vocabulary_builder.get_vocabulary_stats()
        print(f"\n📖 Action Vocabulary:")
        print(f"  • Unique actions: {vocab_stats['total_unique_actions']}")
        print(f"  • Total occurrences: {vocab_stats['total_action_occurrences']}")
        
        print(f"\n🔝 Top 10 Most Frequent Actions:")
        for action, count in vocab_stats['actions_by_frequency'][:10]:
            print(f"  • {action}: {count} times")
        
        categorized = self.vocabulary_builder.categorize_actions()
        print(f"\n📊 Action Categories:")
        for category, actions in categorized.items():
            if actions:
                print(f"  • {category}: {len(actions)} actions")


# Example usage
if __name__ == "__main__":
    # Initialize pipeline with task encoding Excel file
    pipeline = Stage1Pipeline('annotations/encoding/coding manual_UPDATED.xlsx')
    
    # Process single EAF file (example from your data)
    # pipeline.process_eaf_file('GH010406_OT19_Bed_TShirt_Off.eaf')
    
    # Or process entire directory of EAF files
    pipeline.process_directory('annotations')
    
    # Print summary
    pipeline.print_summary()
    
    # Export results
    pipeline.export_results('./stage1_output_alleam/')
    
    print("\n✅ Stage 1 complete!")
    print("Next: Run Stage 2 for pattern analysis and alignment")
    
    # Note: Requires openpyxl for Excel support
    # Install with: pip install openpyxl