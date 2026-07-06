const colors = {
  Device: "#3b82f6",
  Interface: "#64748b",
  OSPFProcess: "#22c55e",
  BGPProcess: "#f97316",
  MPLSL3VPN: "#8b5cf6",
  FHRPGroup: "#14b8a6",
  BusinessService: "#ef4444",
  Application: "#ec4899",
  Change: "#eab308",
  Evidence: "#06b6d4",
  Recommendation: "#84cc16",
  KnowledgeGraphProfile: "#f59e0b",
  CoreOntology: "#0ea5e9",
  TechnologyModule: "#8b5cf6",
};

const activeGraphs = new WeakMap();

function elements(graph) {
  const nodes = graph.nodes.map((node) => ({
    data: {
      id: node.id,
      label: node.label,
      type: node.type,
      properties: node.properties,
      color: colors[node.type] || "#94a3b8",
    },
  }));
  const edges = graph.edges.map((edge) => ({
    data: {
      id: edge.id,
      source: edge.source,
      target: edge.target,
      label: edge.type,
      properties: edge.properties,
    },
  }));
  return [...nodes, ...edges];
}

export function renderGraph(container, graph, onSelect) {
  activeGraphs.get(container)?.destroy();
  const cy = cytoscape({
    container,
    elements: elements(graph),
    style: [
      {
        selector: "node",
        style: {
          "background-color": "data(color)",
          label: "data(label)",
          color: "#e2e8f0",
          "font-size": 10,
          "text-wrap": "wrap",
          "text-max-width": 110,
          "text-valign": "bottom",
          "text-margin-y": 8,
          width: 34,
          height: 34,
        },
      },
      {
        selector: "edge",
        style: {
          width: 1.5,
          "line-color": "#475569",
          "target-arrow-color": "#475569",
          "target-arrow-shape": "triangle",
          "curve-style": "bezier",
          label: "data(label)",
          color: "#94a3b8",
          "font-size": 7,
          "text-rotation": "autorotate",
        },
      },
      {
        selector: ":selected",
        style: { "border-width": 3, "border-color": "#f8fafc" },
      },
    ],
    layout: {
      name: "cose",
      animate: false,
      fit: true,
      padding: 35,
      nodeRepulsion: 7000,
    },
  });

  cy.on("tap", "node", (event) => onSelect(event.target.data()));
  activeGraphs.set(container, cy);
  return cy;
}
