function _chart(d3, width, height, xAxis, yAxis, data, colors, line, x, y, tooltip) {
  d3.select('#schedule svg').remove();

  const svg = d3.select('#schedule')
    .append('svg')
    .attr('viewBox', [0, 0, width, height]);

  svg.append('g').call(xAxis);
  svg.append('g').call(yAxis);

  const train = svg.append('g')
    .attr('stroke-width', 1.5)
    .selectAll('g')
    .data(data)
    .join('g');

  // Add lines.
  train.append('path')
    .attr('fill', 'none')
    .attr('stroke', d => colors[d.type])
    .attr('d', d => line(d.stops));

  // Add stations.
  train.append('g')
    .attr('stroke', 'white')
    .attr('fill', d => colors[d.type])
    .selectAll('circle')
    .data(d => d.stops)
    .join('circle')
    .attr('transform', d => `translate(${x(d.station.distance)},${y(d.time)})`)
    .attr('r', 2.5);

  svg.append('g').call(tooltip);

  return svg.node();
}

function _xAxis(stations, x, margin, height) {
  return g => g
    .style('font', '10px sans-serif')
    .selectAll('g')
    .data(stations)
    .join('g')
      .attr('transform', d => `translate(${x(d.distance)},0)`)
      .call(g => g.append('line')
        .attr('y1', margin.top - 6)
        .attr('y2', margin.top)
        .attr('stroke', 'currentColor'))
      .call(g => g.append('line')
        .attr('y1', height - margin.bottom + 6)
        .attr('y2', height - margin.bottom)
        .attr('stroke', 'currentColor'))
      .call(g => g.append('line')
        .attr('y1', margin.top)
        .attr('y2', height - margin.bottom)
        .attr('stroke-opacity', 0.2)
        .attr('stroke-dasharray', '1.5,2')
        .attr('stroke', 'currentColor'))
      .call(g => g.append('text')
        .attr('transform', `translate(0,${margin.top}) rotate(-90)`)
        .attr('x', 12)
        .attr('dy', '0.35em')
        .text(d => d.name))
      .call(g => g.append('text')
        .attr('text-anchor', 'end')
        .attr('transform', `translate(0,${height - margin.top}) rotate(-90)`)
        .attr('x', -12)
        .attr('dy', '0.35em')
        .text(d => d.name));
}

function _x(d3, stations, margin, width) {
  return d3.scaleLinear()
    .domain(d3.extent(stations, d => d.distance))
    .range([margin.left + 10, width - margin.right]);
}

function _yAxis(d3, y, margin, width) {
  return g => g
    .attr('transform', `translate(${margin.left},0)`)
    .call(d3.axisLeft(y)
      .ticks(d3.utcHour)
      // .tickFormat(d3.utcFormat("%-I %p")))
      .tickFormat(d3.utcFormat('%H:%M')))
    .call(g => g.select('.domain').remove())
    .call(g => g.selectAll('.tick line').clone().lower()
      .attr('stroke-opacity', 0.2)
      .attr('x2', width));
}

function _parseTime(d3) {
  const parseTime = d3.utcParse('%H:%M');
  return string => {
    return parseTime(string);
  };
}

function _tooltip(d3, stops, voronoi, colors, x, y) {
  return g => {
    const formatTime = d3.utcFormat('%H:%M');
    const tooltip = g.append('g')
      .style('font', '10px sans-serif');

    const path = tooltip.append('path')
      .attr('fill', 'white');

    const text = tooltip.append('text');

    const line1 = text.append('tspan')
      .attr('x', 0)
      .attr('y', 0)
      .style('font-weight', 'bold');

    const line2 = text.append('tspan')
      .attr('x', 0)
      .attr('y', '1.1em');

    const line3 = text.append('tspan')
      .attr('x', 0)
      .attr('y', '2.2em');

    g.append('g')
      .attr('fill', 'none')
      .attr('pointer-events', 'all')
      .selectAll('path')
      .data(stops)
      .join('path')
      .attr('d', (d, i) => voronoi.renderCell(i))
      .on('mouseout', () => tooltip.style('display', 'none'))
      .on('mouseover', (event, d) => {
        tooltip.style('display', null);
        line1.text(`${d.train.type}`);
        line2.text(d.stop.station.name);
        line3.text(formatTime(d.stop.time));
        path.attr('stroke', colors[d.train.type]);
        const box = text.node().getBBox();
        path.attr('d', `
          M${box.x - 10},${box.y - 10}
          H${box.width / 2 - 5}l5,-5l5,5
          H${box.width + 10}
          v${box.height + 20}
          h-${box.width + 20}
          z
        `);
        tooltip.attr('transform', `translate(${
          x(d.stop.station.distance) - box.width / 2},${
          y(d.stop.time) + 28
        })`);
      });
  }
}

function _stations(schedule) {
  return schedule.stations;
}

function _stops(d3, schedule) {
  return d3.merge(schedule.map(d => d.stops.map(s => ({train: d, stop: s}))));
}

function _data(schedule, days, direction) {
  const filters = {
    'weekday' : d => /[MTWRF]/.test(d),
    'saturday': d => /[S]/.test(d),
    'sunday'  : d => /[U]/.test(d),
  };

  const directionFilters = {
    'either': () => true,
    'n'     : d  => d.toUpperCase() == 'N',
    's'     : d  => d.toUpperCase() == 'S',
  };

  return schedule.filter(d => filters[days](d.days) && directionFilters[direction](d.direction));
}

function _voronoi(d3, stops, x, y, width, height) {
  return d3.Delaunay
    .from(stops, d => x(d.stop.station.distance), d => y(d.stop.time))
    .voronoi([0, 0, width, height]);
}

function _width() {
  return document.body.clientWidth;
}

function _height() {
  return 3_200;
}

function _margin() {
  return {top: 120, right: 30, bottom: 120, left: 50};
}

function _colors() {
  return {
    A:  'rgb(  0, 168, 231)',
    B:  'rgb( 82, 174,  50)',
    BX: 'rgb(173, 206, 109)',
    C:  'rgb(243, 146,   0)',
    E:  'rgb(124, 110, 176)',
    F:  'rgb(253, 195,   0)',
    H:  'rgb(231,  64,  17)',
  };
}

function _line(d3, x, y) {
  return d3.line()
    .x(d => x(d.station.distance))
    .y(d => y(d.time))
}

export {
  _chart,
  _colors,
  _data,
  _height,
  _line,
  _margin,
  _parseTime,
  _stations,
  _stops,
  _tooltip,
  _voronoi,
  _width,
  _x,
  _xAxis,
  _yAxis,
};
