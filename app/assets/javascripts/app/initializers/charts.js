(function() {
  App.DEFAULT_LINE_CHART_OPTIONS = {
    showLine: false,
    responsive: true,
    maintainAspectRatio: false,
    title: {
      display: false
    },
    tooltips: {
      mode: 'index',
      intersect: false,
      displayColors: false
    },
    hover: {
      mode: 'nearest',
      intersect: true
    },
    legend: {
      display: false
    },
    scales: {
      xAxes: [
        {
          gridLines: {
            display: false
          }
        }
      ],
      yAxes: [
        {
          display: false,
          gridLines: {
            display: false
          },
          ticks: {
            beginAtZero: true,
            callback: function(value) { if (value % 1 === 0) { return value; } }
          }
        }
      ]
    }
  };
  Chart.defaults.global.elements.point.borderColor = 'rgb(68, 182, 84)';
  Chart.defaults.global.elements.point.backgroundColor = '#C3E6C4';
  Chart.defaults.global.elements.point.pointRadius = 1;
  Chart.defaults.global.elements.point.radius = 2;

  Chart.defaults.global.elements.line.borderWidth = 2;
  Chart.defaults.global.elements.line.borderColor = 'rgb(68, 182, 84)';
  Chart.defaults.global.elements.line.backgroundColor = '#C3E6C4';

  Chart.defaults.global.elements.rectangle.borderWidth = 1;
  Chart.defaults.global.elements.rectangle.borderColor = 'rgb(68, 182, 84)';
  Chart.defaults.global.elements.rectangle.backgroundColor = '#C3E6C4';
})();
