exports.config = {
  files: {
    javascripts: {
      joinTo: {
        "js/vendor.js": [
          /(process)/,
          /jquery/,
          "vendor/js/popper.min.js",
          /(underscore)/,
          /(sizzle)/,
          /(priv\/static\/phoenix*)/,
        ],
        "js/admin.js": [
          /(process)/,
          /jquery/,
          /(underscore)/,
          /(sizzle)/,
          /(admin\/js)/,
          /(priv\/static\/phoenix*)/,
        ],
        "js/home.js": /(home\/js)/,
        "js/play.js": /(play\/js)/,
      },
      order: {
        before: [
          "vendor/js/jquery.js",
          "vendor/js/popper.min.js",
          "admin/js/vendor/bootstrap.js",
          "admin/js/vendor/adminlte.js",
          "home/js/vendor/bootstrap.min.js",
        ],
      },
    },
    stylesheets: {
      joinTo: {
        "css/admin.css": /(admin\/css)/,
        "css/home.css": /(home\/css)/,
        "css/play.css": /(play\/css)/,
      },
      order: {
        before: [
          "admin/css/vendor/bootstrap.css",
          "admin/css/vendor/AdminLTE.css",
          "admin/css/vendor/skin-black.css",
          "admin/css/vendor/skin-black-light.css",
          "home/css/vendor/bootstrap.min.css",
        ],
        after: [
          "admin/css/app.css",
        ],
      },
    },
    templates: {
      joinTo: "js/play.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "static",
      "vendor/js",
      "admin/css",
      "admin/js",
      "home/css",
      "home/js",
      "play/css",
      "play/js",
    ],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    sass: {
      mode: 'native'
    },
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/play.js": ["play/js/app"],
      "js/home.js": ["home/js/app"],
      "js/admin.js": ["admin/js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: {
      $: "jquery",
    }
  }
};
