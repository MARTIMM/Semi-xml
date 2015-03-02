use v6;

grammar Semi-xml::Grammar {
  token TOP { <tag> <tag-body> }
  token tag { '$' <tag-id> }
  token tag-body { '[' ( <tag> || .*? )* ']' }
  token tag-id { <[A..Za..z]> <[A..Za..z0..9\:\_\-]>* }
}
