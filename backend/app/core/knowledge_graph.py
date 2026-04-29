from typing import List, Dict, Optional
from collections import deque
import random


class KnowledgeGraphEngine:
    """
    Graph engine simulated over MongoDB using adjacency lists.
    In production, this would connect to Neo4j or Amazon Neptune.
    
    Provides:
    - Pathfinding between topics (BFS shortest path)
    - "Six Degrees of Knowledge" discovery
    - AI-powered learning pathway suggestions
    """

    # Pre-seeded knowledge topics for the global graph
    SEED_TOPICS = {
        "math": ["Linear Algebra", "Calculus", "Statistics", "Probability", "Number Theory", "Discrete Math"],
        "physics": ["Classical Mechanics", "Quantum Mechanics", "Thermodynamics", "Electromagnetism", "Relativity"],
        "cs": ["Data Structures", "Algorithms", "Machine Learning", "Databases", "Operating Systems", "Networks"],
        "biology": ["Cell Biology", "Genetics", "Neuroscience", "Anatomy", "Ecology", "Biochemistry"],
        "chemistry": ["Organic Chemistry", "Inorganic Chemistry", "Physical Chemistry", "Analytical Chemistry"],
    }

    # Pre-seeded relationships
    SEED_EDGES = [
        ("Linear Algebra", "Machine Learning", "prerequisite"),
        ("Calculus", "Classical Mechanics", "prerequisite"),
        ("Statistics", "Machine Learning", "prerequisite"),
        ("Probability", "Statistics", "prerequisite"),
        ("Data Structures", "Algorithms", "prerequisite"),
        ("Algorithms", "Machine Learning", "builds_on"),
        ("Cell Biology", "Genetics", "prerequisite"),
        ("Genetics", "Neuroscience", "related"),
        ("Biochemistry", "Organic Chemistry", "related"),
        ("Quantum Mechanics", "Physical Chemistry", "related"),
        ("Discrete Math", "Data Structures", "prerequisite"),
        ("Number Theory", "Discrete Math", "related"),
        ("Neuroscience", "Machine Learning", "related"),
        ("Databases", "Data Structures", "builds_on"),
        ("Networks", "Operating Systems", "related"),
        ("Thermodynamics", "Physical Chemistry", "related"),
        ("Electromagnetism", "Relativity", "builds_on"),
        ("Anatomy", "Neuroscience", "prerequisite"),
        ("Ecology", "Statistics", "related"),
        ("Calculus", "Linear Algebra", "related"),
    ]

    def __init__(self):
        # Build in-memory adjacency list from seed data
        self.adjacency: Dict[str, List[Dict]] = {}
        self._build_graph()

    def _build_graph(self):
        """Build adjacency list from seed edges."""
        # Add all nodes
        for category, topics in self.SEED_TOPICS.items():
            for topic in topics:
                if topic not in self.adjacency:
                    self.adjacency[topic] = []

        # Add edges (bidirectional for pathfinding)
        for source, target, rel in self.SEED_EDGES:
            self.adjacency.setdefault(source, []).append({"target": target, "relationship": rel})
            self.adjacency.setdefault(target, []).append({"target": source, "relationship": rel})

    def find_path(self, start: str, end: str) -> Optional[List[str]]:
        """BFS shortest path between two topics in the knowledge graph."""
        if start not in self.adjacency or end not in self.adjacency:
            return None

        visited = set()
        queue = deque([(start, [start])])

        while queue:
            current, path = queue.popleft()
            if current == end:
                return path

            if current in visited:
                continue
            visited.add(current)

            for neighbor in self.adjacency.get(current, []):
                target = neighbor["target"]
                if target not in visited:
                    queue.append((target, path + [target]))

        return None

    def six_degrees_of_knowledge(self, topic: str, max_depth: int = 6) -> Dict:
        """
        Discover all topics reachable within max_depth hops.
        Returns connected topics grouped by distance.
        """
        if topic not in self.adjacency:
            return {"topic": topic, "connections": {}}

        visited = set()
        connections: Dict[int, List[str]] = {}
        queue = deque([(topic, 0)])

        while queue:
            current, depth = queue.popleft()
            if depth > max_depth:
                break
            if current in visited:
                continue
            visited.add(current)

            if depth > 0:
                connections.setdefault(depth, []).append(current)

            for neighbor in self.adjacency.get(current, []):
                target = neighbor["target"]
                if target not in visited:
                    queue.append((target, depth + 1))

        return {"topic": topic, "connections": connections}

    def generate_curriculum(self, goal: str, duration_days: int = 30) -> Dict:
        """
        AI-powered curriculum generation.
        Given a learning goal, traverse the knowledge graph to assemble 
        a day-by-day study plan.
        """
        # Simple heuristic: find the most relevant topics based on keyword matching
        goal_lower = goal.lower()
        relevant_topics = []
        
        for topic in self.adjacency:
            if any(word in topic.lower() for word in goal_lower.split()):
                relevant_topics.append(topic)
        
        # If no direct match, pick a random category's topics
        if not relevant_topics:
            all_topics = list(self.adjacency.keys())
            relevant_topics = random.sample(all_topics, min(8, len(all_topics)))

        # Expand with prerequisites and related topics
        expanded = set(relevant_topics)
        for topic in relevant_topics:
            for neighbor in self.adjacency.get(topic, []):
                if neighbor["relationship"] == "prerequisite":
                    expanded.add(neighbor["target"])
        
        expanded = list(expanded)
        
        # Build day-by-day syllabus
        syllabus = []
        topics_per_day = max(1, len(expanded) // duration_days)
        
        for day in range(1, duration_days + 1):
            start_idx = ((day - 1) * topics_per_day) % len(expanded)
            day_topics = expanded[start_idx:start_idx + topics_per_day]
            if not day_topics:
                day_topics = [random.choice(expanded)]
            
            syllabus.append({
                "day": day,
                "title": f"Day {day}: {', '.join(day_topics[:2])}",
                "topics": day_topics,
                "resources": [],
                "estimated_minutes": random.choice([30, 45, 60, 90]),
                "completed": False,
            })
        
        # Generate a smart title and description
        title = f"Master {goal}" if len(goal) < 40 else goal[:50] + "..."
        description = (
            f"A {duration_days}-day AI-generated curriculum covering {len(expanded)} topics. "
            f"Sourced from the global knowledge graph with community-rated content."
        )
        
        return {
            "title": title,
            "description": description,
            "syllabus": syllabus,
            "total_topics": len(expanded),
        }

    def get_all_topics(self) -> List[Dict]:
        """Return all topics in the knowledge graph."""
        topics = []
        for category, topic_list in self.SEED_TOPICS.items():
            for topic in topic_list:
                neighbor_count = len(self.adjacency.get(topic, []))
                topics.append({
                    "title": topic,
                    "category": category,
                    "connections": neighbor_count,
                })
        return topics


# Global singleton
knowledge_graph_engine = KnowledgeGraphEngine()
