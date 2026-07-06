"""Run the protocol-aware KG demonstration."""

import argparse
import os
from collections.abc import Callable
from typing import Any

from dotenv import load_dotenv
from neo4j import Driver, GraphDatabase
from neo4j.exceptions import AuthError, Neo4jError, ServiceUnavailable
from rich.console import Console
from rich.table import Table

from graph_queries import GraphQueries
from queries import (
    design_option_ranking,
    global_change_blast_radius,
    global_interface_blast_radius,
    global_policy_change_impact,
    global_risk_mitigation_validation,
    global_service_protocol_dependencies,
    global_underlay_overlay_impact,
    global_valid_design_options,
    layer2_blocked_ports,
    layer2_bpduguard_ports,
    layer2_design_comparison,
    layer2_service_risks,
    layer2_stp_fhrp_misalignment,
    layer2_unused_vlans,
    likely_prefix_change,
    likely_underlay_cause,
    overlay_service_impact,
    rca_evidence,
    redistributed_prefixes,
    redistribution_controls,
    safe_recommendations,
    technology_complexity_impacts,
    unmitigated_design_risks,
    unsafe_migration_steps,
    unvalidated_assumptions,
    protocol_monitoring_impacts,
    vtep_dependencies,
)


console = Console()
QueryFunction = Callable[[Driver], list[dict[str, Any]]]


def print_rows(question: str, rows: list[dict[str, Any]]) -> None:
    """Print query rows as a compact Rich table."""
    console.print(f"\n[bold]{question}[/bold]")
    if not rows:
        console.print("[yellow]No matching graph data.[/yellow]")
        return

    table = Table(show_header=True, header_style="cyan")
    for column in rows[0]:
        table.add_column(column.replace("_", " ").title())
    for row in rows:
        table.add_row(*(str(value) if value is not None else "—" for value in row.values()))
    console.print(table)


def run_section(
    number: int,
    title: str,
    driver: Driver,
    questions: tuple[tuple[str, QueryFunction], ...],
) -> None:
    console.rule(f"[bold blue]{number}. {title}")
    for question, query_function in questions:
        print_rows(question, query_function(driver))


def print_graph_view(title: str, graph: dict[str, Any]) -> None:
    console.rule(f"[bold blue]{title}")
    console.print(graph["summary"])
    table = Table(show_header=True, header_style="cyan")
    table.add_column("Metric")
    table.add_column("Value", justify="right")
    table.add_row("Nodes", str(len(graph["nodes"])))
    table.add_row("Edges", str(len(graph["edges"])))
    table.add_row("Recommendations", str(len(graph["recommendations"])))
    console.print(table)
    if graph["recommendations"]:
        for recommendation in graph["recommendations"]:
            console.print(
                f"[green]{recommendation.get('name')}:[/green] "
                f"{recommendation.get('action', '')}"
            )
            if recommendation.get("evidence"):
                console.print(
                    f"  [dim]Evidence: {recommendation['evidence']} "
                    f"({recommendation.get('evidence_source', 'source unavailable')})[/dim]"
                )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--chapter-1",
        action="store_true",
        help="Include the optional Layer 2 technology and design section.",
    )
    parser.add_argument(
        "--chapter-2",
        action="store_true",
        help="Include the optional design tools and best practices section.",
    )
    parser.add_argument(
        "--legacy",
        action="store_true",
        help="Run the original MVP tabular demo instead of graph-view projections.",
    )
    args = parser.parse_args()

    load_dotenv()
    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    username = os.getenv("NEO4J_USERNAME", "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password123")
    driver = GraphDatabase.driver(uri, auth=(username, password))

    try:
        driver.verify_connectivity()
        if not args.legacy:
            views = GraphQueries(driver)
            demonstrations = (
                ("1. Protocol local view: OSPF", views.protocol_view("ospf")),
                ("2. Protocol local view: BGP", views.protocol_view("bgp")),
                (
                    "3. Cross-protocol interaction: FHRP → OSPF",
                    views.interaction_view("fhrp", "ospf"),
                ),
                (
                    "4. Cross-protocol interaction: OSPF → BGP",
                    views.interaction_view("ospf", "bgp"),
                ),
                (
                    "5. Cross-protocol interaction: BGP → MPLS",
                    views.interaction_view("bgp", "mpls"),
                ),
                (
                    "6. Service dependency view: Payment-App",
                    views.service_view("Payment-App"),
                ),
                (
                    "7. Change blast radius: CHG-8821",
                    views.change_view("CHG-8821"),
                ),
                (
                    "8. Failure propagation: Ethernet1/49",
                    views.failure_view("Ethernet1/49"),
                ),
            )
            for title, graph in demonstrations:
                print_graph_view(title, graph)
            return
        run_section(
            1,
            "Overlay/Underlay RCA",
            driver,
            (
                ("Which service is impacted by the VXLAN failure?", overlay_service_impact),
                ("Which underlay dependency is the likely cause?", likely_underlay_cause),
                ("What depends on the affected VTEP?", vtep_dependencies),
            ),
        )
        run_section(
            2,
            "Redistribution Impact Analysis",
            driver,
            (
                ("Which prefixes move from OSPF into BGP?", redistributed_prefixes),
                ("Which policies control 10.20.30.0/24?", redistribution_controls),
                ("Which recent change is the likely cause?", likely_prefix_change),
            ),
        )
        run_section(
            3,
            "Evidence and Recommendation",
            driver,
            (
                ("What evidence supports the RCA?", rca_evidence),
                ("What should be validated before remediation?", safe_recommendations),
            ),
        )
        run_section(
            4,
            "Global Network Design KG",
            driver,
            (
                (
                    "What protocol chain supports Payment-App?",
                    global_service_protocol_dependencies,
                ),
                (
                    "What would the simulated access-interface failure impact?",
                    global_interface_blast_radius,
                ),
                (
                    "Which policy change removed the application prefix?",
                    global_policy_change_impact,
                ),
                (
                    "Which underlay failures break overlay services?",
                    global_underlay_overlay_impact,
                ),
                (
                    "Which design options satisfy requirements without violating constraints?",
                    global_valid_design_options,
                ),
                (
                    "What is the Payment-App change blast radius?",
                    global_change_blast_radius,
                ),
                (
                    "What mitigation and validation plan addresses the risk?",
                    global_risk_mitigation_validation,
                ),
            ),
        )
        next_section = 5
        if args.chapter_1:
            run_section(
                next_section,
                "Chapter 1: Layer 2 Technologies",
                driver,
                (
                    (
                        "Which VLANs have misaligned STP and FHRP roles?",
                        layer2_stp_fhrp_misalignment,
                    ),
                    ("Which ports are blocked by STP and why?", layer2_blocked_ports),
                    (
                        "Which access ports are protected by BPDU guard?",
                        layer2_bpduguard_ports,
                    ),
                    ("Which trunks carry unused VLANs?", layer2_unused_vlans),
                    (
                        "Which Layer 2 risks affect a business service?",
                        layer2_service_risks,
                    ),
                    (
                        "How do the access design options compare?",
                        layer2_design_comparison,
                    ),
                ),
            )
            next_section += 1
        if args.chapter_2:
            run_section(
                next_section,
                "Chapter 2: Network Design Decisions",
                driver,
                (
                    (
                        "Which option satisfies the most requirements with least risk?",
                        design_option_ranking,
                    ),
                    ("Which assumptions are unvalidated?", unvalidated_assumptions),
                    (
                        "Which migration steps have unsafe dependencies?",
                        unsafe_migration_steps,
                    ),
                    (
                        "Which protocol changes affect monitoring?",
                        protocol_monitoring_impacts,
                    ),
                    (
                        "Which technology addition increases complexity?",
                        technology_complexity_impacts,
                    ),
                    ("Which risks are not mitigated?", unmitigated_design_risks),
                ),
            )
    except (AuthError, ServiceUnavailable, Neo4jError) as error:
        console.print(f"[bold red]Demo failed:[/bold red] {error}")
        raise SystemExit(1) from error
    finally:
        driver.close()


if __name__ == "__main__":
    main()
