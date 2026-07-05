const encode = encodeURIComponent;

export async function loadGraph(viewType, primary, secondary) {
  const routes = {
    protocol: `/views/protocol/${encode(primary)}`,
    interaction: `/views/interaction/${encode(primary)}/${encode(secondary)}`,
    service: `/views/service/${encode(primary)}`,
    failure: `/views/failure/${encode(primary)}`,
    change: `/views/change/${encode(primary)}`,
    search: `/search?q=${encode(primary)}`,
  };

  const response = await fetch(routes[viewType]);
  if (!response.ok) {
    throw new Error(`Graph request failed: ${response.status}`);
  }
  return response.json();
}
