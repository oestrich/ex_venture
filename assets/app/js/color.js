function formatColor(string) {
  string = string.replace(/{black}/g, "<span class='black'>")
  string = string.replace(/{red}/g, "<span class='red'>")
  string = string.replace(/{green}/g, "<span class='green'>")
  string = string.replace(/{yellow}/g, "<span class='yellow'>")
  string = string.replace(/{blue}/g, "<span class='blue'>")
  string = string.replace(/{magenta}/g, "<span class='magenta'>")
  string = string.replace(/{cyan}/g, "<span class='cyan'>")
  string = string.replace(/{white}/g, "<span class='white'>")
  string = string.replace(/{\/\w+}/g, "</span>")
  return string;
}

function formatLines(string) {
  return string.replace(/\n/g, "<br />")
}

function format(string) {
  return formatLines(formatColor(string));
}

export default format
