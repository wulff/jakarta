import * as gtfs from './common.js';

// TODO: Use generic get_schedule and use a page-specific filter thing to massage it.
async function get_schedule(d3, parseTime, route) {
  if (!['ae', 'bx', 'ch', 'f'].includes(route)) {
    console.log('Invalid line');
    return;
  }

  const data = await d3.tsv('./data/' + route +'.tsv');

  const stations = data.columns
    .filter(key => /^stop\|/.test(key))
    .map(key => {
      const [, name, distance, zone] = key.split('|');
      return {key, name, distance: +distance, zone: +zone};
    });

  return Object.assign(
    data.map(d => ({
      number: d.number,
      type: d.type,
      direction: d.direction,
      days: d.days,
      stops: stations
        .map(station => ({station, time: parseTime(d[station.key])}))
        .filter(station => station.time !== null)
    })),
    {stations}
  );
}

function y_val(d3, parseTime, margin, height){
  const fromDate = parseTime('02:00');
  const toDate = parseTime('04:00');
  toDate.setUTCDate(toDate.getUTCDate() + 1);

  return d3.scaleUtc()
    .domain([fromDate, toDate])
    .range([margin.top, height - margin.bottom]);
}

function main(d3) {
  const parseTime = gtfs._parseTime(d3);

  let elements = {
    days:      document.querySelector('#days'),
    direction: document.querySelector('#direction'),
    line:      document.querySelector('#line'),
  };

  async function draw(d3, width) {
    const days      = elements.days.value;
    const direction = elements.direction.value;
    const route     = elements.line.value;

    let schedule = await get_schedule(d3, parseTime, route);

    const height = gtfs._height();
    const margin = gtfs._margin();

    const stations = gtfs._stations(schedule);

    const x = gtfs._x(d3, stations, margin, width);
    const y = y_val(d3, parseTime, margin, height);

    const xAxis = gtfs._xAxis(stations, x, margin, height);
    const yAxis = gtfs._yAxis(d3, y, margin, width);

    const data = gtfs._data(schedule, days, direction);
    const colors = gtfs._colors();
    const line = gtfs._line(d3, x, y);

    const stops = gtfs._stops(d3, data);
    const voronoi = gtfs._voronoi(d3, stops, x, y, width, height)
    const tooltip = gtfs._tooltip(d3, stops, voronoi, colors, x, y);

    gtfs._chart(d3, width, height, xAxis, yAxis, data, colors, line, x, y, tooltip);
  }

  let width = gtfs._width();
  let resizeTimer = setTimeout(() => draw(d3, width), 0);

  window.addEventListener('resize', () => {
    const w = gtfs._width();
    if (width !== w) {
      width = w;
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => draw(d3, width), 10);
    }
  });

  window.addEventListener('change', (event) => {
    if (event.target.matches('#line,#direction,#days')) {
      const w = gtfs._width();
      draw(d3, width);
    }
  });
}

main(d3);
