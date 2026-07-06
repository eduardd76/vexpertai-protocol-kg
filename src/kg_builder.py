"""Build and persist scoped technology profiles inside the unified KG."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from neo4j import Driver

try:
    from .config import get_settings
except ImportError:
    from config import get_settings


TECHNOLOGIES = (
    {
        "id": "layer2",
        "name": "Layer 2 / STP / FHRP",
        "description": "VLAN, switching, spanning tree, and default-gateway roles.",
    },
    {
        "id": "ospf",
        "name": "OSPF",
        "description": "Areas, adjacencies, reachability, and redistribution origin.",
    },
    {
        "id": "bgp",
        "name": "BGP",
        "description": "Sessions, routes, next-hop resolution, and route policy.",
    },
    {
        "id": "mpls",
        "name": "MPLS",
        "description": "LSP, label, transport, and L3VPN forwarding dependencies.",
    },
    {
        "id": "vpn",
        "name": "VPN",
        "description": "IPsec, DMVPN, tunnel, and underlay transport dependencies.",
    },
    {
        "id": "segment-routing",
        "name": "Segment Routing",
        "description": "SID advertisements, segment lists, and SR policy.",
    },
    {
        "id": "qos",
        "name": "QoS",
        "description": "Classification, policy application, congestion, and SLA protection.",
    },
    {
        "id": "security",
        "name": "Security Policy",
        "description": "Firewall rules, traffic flows, zones, and application path control.",
    },
)

INTERACTIONS = (
    {
        "id": "fhrp-ospf",
        "source": "layer2",
        "target": "ospf",
        "name": "FHRP tracks IGP reachability",
    },
    {
        "id": "ospf-bgp",
        "source": "ospf",
        "target": "bgp",
        "name": "OSPF reachability and redistribution support BGP",
    },
    {
        "id": "bgp-mpls",
        "source": "bgp",
        "target": "mpls",
        "name": "BGP VPN routes require MPLS labels",
    },
    {
        "id": "mpls-vpn",
        "source": "mpls",
        "target": "vpn",
        "name": "VPN services use MPLS transport",
    },
    {
        "id": "igp-segment-routing",
        "source": "ospf",
        "target": "segment-routing",
        "name": "IGP advertises Segment Routing SIDs",
    },
    {
        "id": "overlay-underlay",
        "source": "ospf",
        "target": "vpn",
        "name": "VPN overlay depends on routed underlay",
    },
)

TECHNOLOGY_BY_ID = {technology["id"]: technology for technology in TECHNOLOGIES}


@dataclass(frozen=True)
class ProfileInput:
    name: str
    technologies: tuple[str, ...]
    sites: tuple[str, ...] = ()
    notes: str = ""


class KGBuilder:
    def __init__(self, driver: Driver | None = None):
        self.driver = driver
        self.database = get_settings().neo4j_database

    @staticmethod
    def catalog() -> dict[str, Any]:
        return {
            "technologies": list(TECHNOLOGIES),
            "interactions": list(INTERACTIONS),
        }

    @staticmethod
    def _normalize(profile: ProfileInput) -> ProfileInput:
        name = profile.name.strip()
        if not name:
            raise ValueError("Profile name is required.")
        technology_ids = tuple(dict.fromkeys(profile.technologies))
        unknown = sorted(set(technology_ids) - set(TECHNOLOGY_BY_ID))
        if unknown:
            raise ValueError(f"Unknown technologies: {', '.join(unknown)}")
        if not technology_ids:
            raise ValueError("Select at least one technology.")
        return ProfileInput(
            name=name,
            technologies=technology_ids,
            sites=tuple(site.strip() for site in profile.sites if site.strip()),
            notes=profile.notes.strip(),
        )

    @staticmethod
    def _profile_id(name: str) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        return f"kg-profile-{slug or 'network'}"

    @staticmethod
    def _warnings(selected: set[str]) -> list[dict[str, str]]:
        warnings: list[dict[str, str]] = []
        if "bgp" in selected and "ospf" not in selected:
            warnings.append(
                {
                    "name": "BGP has no modeled IGP",
                    "action": (
                        "Add OSPF unless this is intentionally a pure eBGP edge; "
                        "otherwise BGP next-hop reachability is incomplete."
                    ),
                }
            )
        if "mpls" in selected and "ospf" not in selected:
            warnings.append(
                {
                    "name": "MPLS has no modeled IGP underlay",
                    "action": "Add OSPF so LSP and label state can trace to routed reachability.",
                }
            )
        if "vpn" in selected and not ({"ospf", "mpls"} & selected):
            warnings.append(
                {
                    "name": "VPN has no modeled underlay",
                    "action": "Add OSPF or MPLS to represent tunnel transport dependencies.",
                }
            )
        if "segment-routing" in selected and "ospf" not in selected:
            warnings.append(
                {
                    "name": "Segment Routing has no SID-advertising IGP",
                    "action": "Add OSPF to model SID advertisement and underlay reachability.",
                }
            )
        return warnings

    def preview(self, profile: ProfileInput) -> dict[str, Any]:
        profile = self._normalize(profile)
        selected = set(profile.technologies)
        profile_id = self._profile_id(profile.name)
        nodes = [
            {
                "id": profile_id,
                "label": profile.name,
                "type": "KnowledgeGraphProfile",
                "properties": {
                    "id": profile_id,
                    "name": profile.name,
                    "sites": list(profile.sites),
                    "notes": profile.notes,
                },
            },
            {
                "id": "shared-network-core",
                "label": "Shared Network Core",
                "type": "CoreOntology",
                "properties": {
                    "id": "shared-network-core",
                    "name": "Shared Network Core",
                    "description": (
                        "Device, interface, route, policy, application, "
                        "and service concepts."
                    ),
                },
            },
        ]
        edges = [
            {
                "id": f"{profile_id}-uses-core",
                "source": profile_id,
                "target": "shared-network-core",
                "type": "USES_CORE",
                "properties": {},
            }
        ]

        for technology_id in profile.technologies:
            technology = TECHNOLOGY_BY_ID[technology_id]
            node_id = f"technology-{technology_id}"
            nodes.append(
                {
                    "id": node_id,
                    "label": technology["name"],
                    "type": "TechnologyModule",
                    "properties": dict(technology),
                }
            )
            edges.extend(
                (
                    {
                        "id": f"{profile_id}-enables-{technology_id}",
                        "source": profile_id,
                        "target": node_id,
                        "type": "ENABLES_MODULE",
                        "properties": {},
                    },
                    {
                        "id": f"{technology_id}-extends-core",
                        "source": node_id,
                        "target": "shared-network-core",
                        "type": "EXTENDS_CORE",
                        "properties": {},
                    },
                )
            )

        applicable = [
            interaction
            for interaction in INTERACTIONS
            if {interaction["source"], interaction["target"]} <= selected
        ]
        for interaction in applicable:
            edges.append(
                {
                    "id": f"interaction-{interaction['id']}",
                    "source": f"technology-{interaction['source']}",
                    "target": f"technology-{interaction['target']}",
                    "type": interaction["id"].upper().replace("-", "_"),
                    "properties": {"name": interaction["name"]},
                }
            )

        return {
            "nodes": nodes,
            "edges": edges,
            "summary": (
                f"{profile.name} uses {len(selected)} technology modules and "
                f"{len(applicable)} cross-protocol interaction models in one shared KG."
            ),
            "recommendations": self._warnings(selected),
        }

    def save(self, profile: ProfileInput) -> dict[str, Any]:
        if self.driver is None:
            raise RuntimeError("Neo4j driver is required to save a profile.")
        profile = self._normalize(profile)
        graph = self.preview(profile)
        profile_id = self._profile_id(profile.name)
        modules = [TECHNOLOGY_BY_ID[item] for item in profile.technologies]

        with self.driver.session(database=self.database) as session:
            session.execute_write(
                self._save_profile,
                profile_id,
                profile,
                modules,
            )
        graph["summary"] += " Profile saved to Neo4j."
        return graph

    @staticmethod
    def _save_profile(tx, profile_id: str, profile: ProfileInput, modules) -> None:
        tx.run(
            """
            MERGE (profile:KnowledgeGraphProfile {id: $profile_id})
            SET profile.name = $name,
                profile.sites = $sites,
                profile.notes = $notes,
                profile.technologies = $technology_ids,
                profile.dataset = 'vexpertai-builder',
                profile.updated_at = datetime()
            WITH profile
            OPTIONAL MATCH (profile)-[existing:USES_TECHNOLOGY]->()
            DELETE existing
            """,
            profile_id=profile_id,
            name=profile.name,
            sites=list(profile.sites),
            notes=profile.notes,
            technology_ids=list(profile.technologies),
        ).consume()
        tx.run(
            """
            MATCH (profile:KnowledgeGraphProfile {id: $profile_id})
            UNWIND $modules AS selected
            MERGE (module:TechnologyModule {id: selected.node_id})
            SET module.name = selected.name,
                module.technology_id = selected.technology_id,
                module.description = selected.description,
                module.dataset = 'vexpertai-builder'
            MERGE (profile)-[:USES_TECHNOLOGY]->(module)
            """,
            profile_id=profile_id,
            modules=[
                {
                    "node_id": f"technology-{module['id']}",
                    "technology_id": module["id"],
                    "name": module["name"],
                    "description": module["description"],
                }
                for module in modules
            ],
        ).consume()

    def list_profiles(self) -> list[dict[str, Any]]:
        if self.driver is None:
            raise RuntimeError("Neo4j driver is required to list profiles.")
        with self.driver.session(database=self.database) as session:
            return [
                record.data()
                for record in session.run(
                    """
                    MATCH (profile:KnowledgeGraphProfile)
                    RETURN profile.id AS id,
                           profile.name AS name,
                           profile.sites AS sites,
                           profile.technologies AS technologies,
                           toString(profile.updated_at) AS updated_at
                    ORDER BY toLower(profile.name)
                    """
                )
            ]

    def get_profile(self, profile_id: str) -> dict[str, Any] | None:
        if self.driver is None:
            raise RuntimeError("Neo4j driver is required to load a profile.")
        with self.driver.session(database=self.database) as session:
            record = session.run(
                """
                MATCH (profile:KnowledgeGraphProfile {id: $profile_id})
                RETURN profile.name AS name,
                       profile.sites AS sites,
                       profile.notes AS notes,
                       profile.technologies AS technologies
                """,
                profile_id=profile_id,
            ).single()
        if record is None:
            return None
        return self.preview(
            ProfileInput(
                name=record["name"],
                technologies=tuple(record["technologies"] or ()),
                sites=tuple(record["sites"] or ()),
                notes=record["notes"] or "",
            )
        )
