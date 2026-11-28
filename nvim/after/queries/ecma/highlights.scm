;; extends

; imported names (`cn` in `import { cn } from ...`) use the accent; tsc sends no semantic token for them
(import_specifier name: (identifier) @import.name)
(import_specifier alias: (identifier) @import.name)
(import_clause (identifier) @import.name)
(namespace_import (identifier) @import.name)
