const path = require("path");
const webpack = require("webpack");
const BundleTracker = require('webpack-bundle-tracker');

module.exports = {
    entry: "./src/index.js",
    output: {
        path: path.resolve(__dirname, "./build/static"),
        filename: "[name].js",
    },
    // entry: {
    //     base: '../core/static/js/base.js'
    // },
    // output: {
    //     path: path.resolve("../static/js/bundles"),
    //     filename: "[name].js",
    // },
    module: {
        rules: [
            {
                test: /\.js|.jsx$/,
                exclude: /node_modules/,
                use: "babel-loader",
            },
            {
                test: /\.css$/,
                exclude: /node_modules/,
                use: ["style-loader", "css-loader"],
            },
            {
                test: /\.svg$/,
                use: ['svg-inline-loader']
            },
        ],
    },
    // watch: true,
    optimization: {
        minimize: true,
    },
    plugins: [
        new webpack.DefinePlugin({
            "process.env": {
                NODE_ENV: JSON.stringify("development"),
            },
        }),
        new BundleTracker({filename: './webpack-stats.json'}),
    ],
};