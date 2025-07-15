Vue.component('app-pagination', {
    template: '#pagination-tmpl',
    props: {
      total: {
        type: Number,
        required: true
      },
      pageSize: {
        type: Number,
        required: true
      },
      callback: {
        type: Function,
        required: true
      },
      options: {
        type: Object
      },
      navClass:{
        type: String,
        default: ""
      },
      ulClass:{
        type: String,
        default: ""
      },
      liClass:{
        type: String,
        default: ""
      },
      currentPage: {
        type: Number,
        default: 1
      }
    },
    computed: {
      _total: function() { return this.total },
      _pageSize: function() { return this.pageSize },
      lastPage: function() {
        var _total = this._total / this._pageSize;
        if (_total < 1)
          return 1;

        if (_total % 1 != 0)
          return parseInt(_total + 1);

        return _total;
      },
      array: function() {

        var _from = this.currentPage - this.config.offset;
        if (_from < 1)
          _from = 1;

        var _to = _from + (this.config.offset * 2);
        if (_to >= this.lastPage)
          _to = this.lastPage;

        var _arr = [];
        while (_from <= _to) {
          _arr.push(_from);
          _from++;
        }

        return _arr;
      },
      config: function() {
        return Object.assign({
          offset: 2,
          ariaNext: 'Próximo',
          ariaPrevious: 'Anterior',
          previousText: '«',
          nextText: '»',
          alwaysShowPrevNext: true
        }, this.options);
      }
    },
    methods: {
      showPrevious: function() {
        return this.config.alwaysShowPrevNext || this.currentPage > 1;
      },
      showNext: function() {
        return this.config.alwaysShowPrevNext || this.currentPage < this.lastPage;
      },
      changePage: function(page) {
        if (this.currentPage === page) return;
        this.callback(page);
      }
    }
})
