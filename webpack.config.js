const path = require('path');

const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    mode: 'development',

    entry: './app/index.js',

    output: {
        path: path.resolve(__dirname, 'dist/'),
        filename: 'app.js',
        publicPath: '/',
    },

    module: {
        rules: [
        ],
    },

    devServer: {
        static: {
            directory: path.resolve(__dirname, 'dist/')
        },
        port: 3000
    },

    plugins: [
        new HtmlWebpackPlugin({
            template: './src/client/index.html',
            filename: 'index.html',
        }),
    ],

};
