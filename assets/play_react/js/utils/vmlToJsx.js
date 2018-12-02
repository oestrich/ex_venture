import React from 'react';

// This was originally an html parser written by @HenrikJoreteg and @Philip_Roberts.
// The original repo this was taken from: https://github.com/HenrikJoreteg/html-parse-stringify

var attrRE = /([\w-]+)|['"]{1}([^'"]*)['"]{1}/g;

// create optimized lookup object for
// void elements as listed here:
// http://www.w3.org/html/wg/drafts/html/master/syntax.html#void-elements
var lookup = Object.create ? Object.create(null) : {};
lookup.area = true;
lookup.base = true;
lookup.br = true;
lookup.col = true;
lookup.embed = true;
lookup.hr = true;
lookup.img = true;
lookup.input = true;
lookup.keygen = true;
lookup.link = true;
lookup.menuitem = true;
lookup.meta = true;
lookup.param = true;
lookup.source = true;
lookup.track = true;
lookup.wbr = true;

function parseTag(tag) {
  var i = 0;
  var key;
  var res = {
    type: 'tag',
    name: '',
    voidElement: false,
    attrs: {},
    children: []
  };

  tag.replace(attrRE, function(match) {
    if (i % 2) {
      key = match;
    } else {
      if (i === 0) {
        if (lookup[match] || tag.charAt(tag.length - 2) === '/') {
          res.voidElement = true;
        }
        res.name = match;
      } else {
        res.attrs[key] = match.replace(/['"]/g, '');
      }
    }
    i++;
  });

  return res;
}

/*jshint -W030 */
// re-used obj for quick lookups of components
var empty = Object.create ? Object.create(null) : {};

export function vmlToAst(html, options) {
  var tagRE = /\{(?:"[^"]*"['"]*|'[^']*'['"]*|[^'"\}])+\}/g;
  options || (options = {});
  options.components || (options.components = empty);
  var result = [];
  var current;
  var level = -1;
  var arr = [];
  var byTag = {};
  var inComponent = false;

  html.replace(tagRE, function(tag, index) {
    if (inComponent) {
      if (tag !== '{/' + current.name + '}') {
        return;
      } else {
        inComponent = false;
      }
    }
    var isOpen = tag.charAt(1) !== '/';
    var start = index + tag.length;
    var nextChar = html.charAt(start);
    var parent;

    if (isOpen) {
      level++;

      current = parseTag(tag);
      if (current.type === 'tag' && options.components[current.name]) {
        current.type = 'component';
        inComponent = true;
      }

      if (
        !current.voidElement &&
        !inComponent &&
        nextChar &&
        nextChar !== '{'
      ) {
        current.children.push({
          type: 'text',
          content: html.slice(start, html.indexOf('{', start))
        });
      }

      byTag[current.tagName] = current;

      // if we're at root, push new base node
      if (level === 0) {
        result.push(current);
      }

      parent = arr[level - 1];

      if (parent) {
        parent.children.push(current);
      }

      arr[level] = current;
    }

    if (!isOpen || current.voidElement) {
      level--;
      if (!inComponent && nextChar !== '{' && nextChar) {
        // trailing text node
        // if we're at the root, push a base text node. otherwise add as
        // a child to the current node.
        parent = level === -1 ? result : arr[level].children;

        // calculate correct end of the content slice in case there's
        // no tag after the text node.
        var end = html.indexOf('{', start);
        var content = html.slice(start, end === -1 ? undefined : end);
        // if a node is nothing but whitespace, no need to add it.
        if (!/^\s*$/.test(content)) {
          parent.push({
            type: 'text',
            content: content
          });
        }
      }
    }
  });

  return result;
}
