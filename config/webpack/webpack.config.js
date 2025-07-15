const { webpackConfig: baseWebpackConfig, merge } = require('shakapacker')
const webpack = require("webpack");
const options = {
  resolve: {
    extensions: ['.css', '.scss', '.jpg', '.png']
  },
  plugins: [
    new webpack.ContextReplacementPlugin(/^\.\/locale$/, /moment$/)
  ]
}

module.exports = merge({}, baseWebpackConfig, options)