exports.config = {
  files: {
    javascripts: {
      joinTo: {
        "js/app.js": /(jquery)|(process)|(underscore)|(sizzle)|(app\/js)|(priv\/static\/phoenix*)/,
        "js/admin.js": /(process)|(jquery)|(underscore)|(sizzle)|(admin\/js)|(priv\/static\/phoenix*)/,
        "js/home.js": /(jquery)|(process)|(home\/js)/,
      },
      order: {
        before: [
          /jquery/,
          "admin/js/vendor/bootstrap.js",
          "admin/js/vendor/adminlte.js",
          "home/js/vendor/jquery-3.2.1.js",
          "home/js/vendor/popper.min.js",
        ],
        after: [
          "admin/js/app.js"
        ],
      },
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /(app\/css)/,
        "css/admin.css": /(admin\/css)/,
        "css/home.css": /(home\/css)/,
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
      joinTo: "js/app.js"
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
    watched: ["static", "admin/css", "admin/js", "app/css", "app/js", "home/css", "home/js", "vendor"],
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
      "js/app.js": ["js/app"],
      "js/admin.js": ["admin/js/socket"]
    }
  },

  npm: {
    enabled: true,
    globals: {
      $: "jquery",
    }
  }
};
