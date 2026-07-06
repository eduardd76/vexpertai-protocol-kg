import { loadGraph } from "./api.js";
import { renderGraph } from "./graphView.js";

const viewType = document.querySelector("#view-type");
const primaryInput = document.querySelector("#primary-input");
const secondaryInput = document.querySelector("#secondary-input");
const secondaryField = document.querySelector("#secondary-field");
const loadButton = document.querySelector("#load-view");
const graphContainer = document.querySelector("#graph");
const properties = document.querySelector("#node-properties");
const summary = document.querySelector("#summary");
const recommendations = document.querySelector("#recommendations");

const defaults = {
  protocol: ["ospf", ""],
  interaction: ["ospf", "bgp"],
  service: ["Payment-App", ""],
  failure: ["Ethernet1/49", ""],
  change: ["CHG-8821", ""],
  search: ["Payment", ""],
};

function updateInputs() {
  const [primary, secondary] = defaults[viewType.value];
  primaryInput.value = primary;
  secondaryInput.value = secondary;
  secondaryField.classList.toggle("hidden", viewType.value !== "interaction");
}

async function refresh() {
  loadButton.disabled = true;
  summary.textContent = "Loading…";
  try {
    const graph = await loadGraph(
      viewType.value,
      primaryInput.value.trim(),
      secondaryInput.value.trim(),
    );
    renderGraph(graphContainer, graph, (selected) => {
      properties.textContent = JSON.stringify(
        { type: selected.type, ...selected.properties },
        null,
        2,
      );
    });
    summary.textContent = graph.summary;
    recommendations.replaceChildren();
    if (!graph.recommendations.length) {
      recommendations.textContent = "None.";
    }
    for (const item of graph.recommendations) {
      const article = document.createElement("article");
      const name = document.createElement("strong");
      const action = document.createElement("p");
      const evidence = document.createElement("p");
      name.textContent = item.name;
      action.textContent = item.action || "";
      evidence.className = "evidence";
      evidence.textContent = item.evidence
        ? `Evidence: ${item.evidence} (${item.evidence_source || "source unavailable"})`
        : "Evidence source unavailable.";
      article.append(name, action, evidence);
      recommendations.append(article);
    }
  } catch (error) {
    summary.textContent = error.message;
  } finally {
    loadButton.disabled = false;
  }
}

viewType.addEventListener("change", updateInputs);
loadButton.addEventListener("click", refresh);
updateInputs();
refresh();
