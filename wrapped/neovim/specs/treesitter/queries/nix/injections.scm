;; extends

; strings following mkLuaInline are lua
((apply_expression
   function: (_) @_func
   argument: [
     (string_expression (string_fragment) @injection.content)
     (indented_string_expression (string_fragment) @injection.content)
   ])
 (#match? @_func "mkLuaInline$")
 (#set! injection.language "lua")
 (#set! injection.combined))
