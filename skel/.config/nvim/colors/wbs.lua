-- wbs.lua — tema claro para aula/retroprojetor
vim.g.colors_name = 'wbs'
vim.o.background  = 'light'

local hi = vim.api.nvim_set_hl

local bg       = '#ffffff'
local bg_alt   = '#efefef'
local fg       = '#111111'
local comment  = '#777777'   -- NÃO ALTERAR
local blue     = '#0022bb'
local red      = '#aa0000'
local green    = '#005500'
local purple   = '#5500aa'
local orange   = '#bb4400'
local teal     = '#005f6e'
local grey_ui  = '#cccccc'

-- ============================================================
-- Editor base
-- ============================================================
hi(0, 'Normal',        { fg = fg,        bg = bg })
hi(0, 'NormalNC',      { fg = fg,        bg = bg })
hi(0, 'NormalFloat',   { fg = fg,        bg = bg_alt })
hi(0, 'FloatBorder',   { fg = grey_ui,   bg = bg_alt })

hi(0, 'CursorLine',    { bg = bg_alt })
hi(0, 'CursorLineNr',  { fg = blue,      bg = bg_alt, bold = true })
hi(0, 'LineNr',        { fg = '#aaaaaa' })
hi(0, 'SignColumn',    { bg = bg })
hi(0, 'ColorColumn',   { bg = bg_alt })

hi(0, 'Visual',        { bg = '#c8d8ff' })
hi(0, 'VisualNOS',     { bg = '#c8d8ff' })
hi(0, 'Search',        { fg = fg,        bg = '#ffe066', bold = true })
hi(0, 'IncSearch',     { fg = '#ffffff', bg = orange,   bold = true })
hi(0, 'CurSearch',     { fg = '#ffffff', bg = orange,   bold = true })
hi(0, 'MatchParen',    { fg = orange,    bold = true,   underline = true })

hi(0, 'Pmenu',         { fg = fg,        bg = bg_alt })
hi(0, 'PmenuSel',      { fg = '#ffffff', bg = blue })
hi(0, 'PmenuSbar',     { bg = grey_ui })
hi(0, 'PmenuThumb',    { bg = '#888888' })

hi(0, 'StatusLine',    { fg = fg,        bg = grey_ui })
hi(0, 'StatusLineNC',  { fg = comment,   bg = grey_ui })
hi(0, 'WinSeparator',  { fg = grey_ui })
hi(0, 'VertSplit',     { fg = grey_ui })

hi(0, 'TabLine',       { fg = comment,   bg = grey_ui })
hi(0, 'TabLineSel',    { fg = fg,        bg = bg,     bold = true })
hi(0, 'TabLineFill',   { bg = grey_ui })

hi(0, 'Folded',        { fg = comment,   bg = bg_alt, italic = true })
hi(0, 'FoldColumn',    { fg = comment,   bg = bg })
hi(0, 'NonText',       { fg = grey_ui })
hi(0, 'SpecialKey',    { fg = grey_ui })
hi(0, 'Whitespace',    { fg = grey_ui })
hi(0, 'EndOfBuffer',   { fg = grey_ui })

hi(0, 'ErrorMsg',      { fg = '#ffffff', bg = red,    bold = true })
hi(0, 'WarningMsg',    { fg = orange,    bold = true })
hi(0, 'ModeMsg',       { fg = fg,        bold = true })
hi(0, 'MoreMsg',       { fg = green })
hi(0, 'Question',      { fg = blue })
hi(0, 'Directory',     { fg = blue,      bold = true })
hi(0, 'Title',         { fg = purple,    bold = true })

-- ============================================================
-- Syntax (legacy)
-- ============================================================
hi(0, 'Comment',       { fg = comment,  italic = true })

hi(0, 'Keyword',       { fg = blue,     bold = true })
hi(0, 'Statement',     { fg = blue,     bold = true })
hi(0, 'Conditional',   { fg = blue,     bold = true })
hi(0, 'Repeat',        { fg = blue,     bold = true })
hi(0, 'Exception',     { fg = blue,     bold = true })
hi(0, 'Label',         { fg = blue,     bold = true })
hi(0, 'Operator',      { fg = fg })

hi(0, 'Function',      { fg = green,    bold = true })
hi(0, 'Identifier',    { fg = fg })

hi(0, 'String',        { fg = red })
hi(0, 'Character',     { fg = red })

hi(0, 'Number',        { fg = orange })
hi(0, 'Float',         { fg = orange })
hi(0, 'Boolean',       { fg = orange,   bold = true })
hi(0, 'Constant',      { fg = orange })

hi(0, 'Type',          { fg = purple,   bold = true })
hi(0, 'StorageClass',  { fg = purple,   bold = true })
hi(0, 'Structure',     { fg = purple,   bold = true })
hi(0, 'Typedef',       { fg = purple,   bold = true })

hi(0, 'PreProc',       { fg = teal,     bold = true })
hi(0, 'Include',       { fg = teal,     bold = true })
hi(0, 'Define',        { fg = teal,     bold = true })
hi(0, 'Macro',         { fg = teal,     bold = true })
hi(0, 'PreCondit',     { fg = teal,     bold = true })

hi(0, 'Special',       { fg = teal })
hi(0, 'SpecialChar',   { fg = teal })
hi(0, 'Tag',           { fg = teal })
hi(0, 'Delimiter',     { fg = fg })
hi(0, 'SpecialComment',{ fg = comment,  bold = true })
hi(0, 'Debug',         { fg = orange })

hi(0, 'Underlined',    { underline = true })
hi(0, 'Error',         { fg = red,      bold = true })
hi(0, 'Todo',          { fg = '#ffffff', bg = orange, bold = true })

-- ============================================================
-- Treesitter
-- ============================================================
hi(0, '@comment',                   { fg = comment,  italic = true })

hi(0, '@keyword',                   { fg = blue,     bold = true })
hi(0, '@keyword.function',          { fg = blue,     bold = true })
hi(0, '@keyword.return',            { fg = blue,     bold = true })
hi(0, '@keyword.operator',          { fg = blue,     bold = true })
hi(0, '@keyword.import',            { fg = teal,     bold = true })
hi(0, '@keyword.import.c',          { fg = teal,     bold = true })
hi(0, '@keyword.directive',         { fg = teal,     bold = true })  -- #include #define
hi(0, '@keyword.directive.define',  { fg = teal,     bold = true })
hi(0, '@conditional',               { fg = blue,     bold = true })
hi(0, '@repeat',                    { fg = blue,     bold = true })
hi(0, '@exception',                 { fg = blue,     bold = true })
hi(0, '@operator',                  { fg = fg })
hi(0, '@punctuation',                   { fg = fg })
hi(0, '@punctuation.bracket',           { fg = fg })
hi(0, '@punctuation.delimiter',         { fg = fg })
hi(0, '@punctuation.delimiter.c',       { fg = teal, bold = true })  -- # em #include
hi(0, '@punctuation.special',           { fg = teal, bold = true })
hi(0, '@punctuation.special.c',         { fg = teal, bold = true })

hi(0, '@function',                  { fg = green,    bold = true })
hi(0, '@function.builtin',          { fg = green,    bold = true })
hi(0, '@function.call',             { fg = green })
hi(0, '@function.macro',            { fg = teal,     bold = true })
hi(0, '@method',                    { fg = green,    bold = true })
hi(0, '@method.call',               { fg = green })
hi(0, '@constructor',               { fg = purple,   bold = true })

hi(0, '@variable',                  { fg = fg })
hi(0, '@variable.builtin',          { fg = teal,     bold = true })
hi(0, '@variable.parameter',        { fg = fg })       -- parâmetros de função
hi(0, '@variable.member',           { fg = fg })
hi(0, '@parameter',                 { fg = fg })
hi(0, '@field',                     { fg = fg })
hi(0, '@property',                  { fg = fg })

hi(0, '@type',                      { fg = purple,   bold = true })
hi(0, '@type.builtin',              { fg = purple,   bold = true })
hi(0, '@type.definition',           { fg = purple,   bold = true })
hi(0, '@type.qualifier',            { fg = blue,     bold = true })  -- const, volatile

hi(0, '@string',                    { fg = red })
hi(0, '@string.escape',             { fg = teal })
hi(0, '@string.special',            { fg = red })
hi(0, '@string.special.path',       { fg = red })      -- <stdio.h> após #include
hi(0, '@character',                 { fg = red })
hi(0, '@number',                    { fg = orange })
hi(0, '@float',                     { fg = orange })
hi(0, '@boolean',                   { fg = orange,   bold = true })
hi(0, '@constant',                  { fg = orange })
hi(0, '@constant.builtin',          { fg = orange,   bold = true })  -- NULL, true, false
hi(0, '@constant.macro',            { fg = orange,   bold = true })  -- NULL via macro

hi(0, '@preproc',                   { fg = teal,     bold = true })
hi(0, '@include',                   { fg = teal,     bold = true })
hi(0, '@define',                    { fg = teal,     bold = true })

hi(0, '@namespace',                 { fg = purple })
hi(0, '@module',                    { fg = purple })
hi(0, '@label',                     { fg = blue,     bold = true })

hi(0, '@tag',                       { fg = blue,     bold = true })
hi(0, '@tag.attribute',             { fg = teal })
hi(0, '@tag.delimiter',             { fg = fg })

-- ============================================================
-- LSP semantic tokens (clangd, pyright, etc.)
-- ============================================================
hi(0, '@lsp.type.function',         { fg = green,    bold = true })
hi(0, '@lsp.type.method',           { fg = green,    bold = true })
hi(0, '@lsp.type.variable',         { fg = fg })
hi(0, '@lsp.type.parameter',        { fg = fg })
hi(0, '@lsp.type.property',         { fg = fg })
hi(0, '@lsp.type.field',            { fg = fg })
hi(0, '@lsp.type.type',             { fg = purple,   bold = true })
hi(0, '@lsp.type.class',            { fg = purple,   bold = true })
hi(0, '@lsp.type.struct',           { fg = purple,   bold = true })
hi(0, '@lsp.type.enum',             { fg = purple,   bold = true })
hi(0, '@lsp.type.enumMember',       { fg = orange })
hi(0, '@lsp.type.interface',        { fg = purple,   bold = true })
hi(0, '@lsp.type.typeParameter',    { fg = purple })
hi(0, '@lsp.type.namespace',        { fg = purple })
hi(0, '@lsp.type.module',           { fg = purple })
hi(0, '@lsp.type.macro',            { fg = teal,     bold = true })
hi(0, '@lsp.type.keyword',          { fg = blue,     bold = true })
hi(0, '@lsp.type.comment',          { fg = comment,  italic = true })
hi(0, '@lsp.type.string',           { fg = red })
hi(0, '@lsp.type.number',           { fg = orange })
hi(0, '@lsp.type.operator',         { fg = fg })
hi(0, '@lsp.type.decorator',        { fg = teal })

-- modificadores semânticos
hi(0, '@lsp.mod.readonly',          { fg = orange })
hi(0, '@lsp.mod.static',            { fg = fg,       italic = true })
hi(0, '@lsp.mod.deprecated',        { strikethrough = true })

-- ============================================================
-- Diagnósticos LSP
-- ============================================================
hi(0, 'DiagnosticError',            { fg = red })
hi(0, 'DiagnosticWarn',             { fg = orange })
hi(0, 'DiagnosticInfo',             { fg = blue })
hi(0, 'DiagnosticHint',             { fg = teal })
hi(0, 'DiagnosticUnderlineError',   { sp = red,      undercurl = true })
hi(0, 'DiagnosticUnderlineWarn',    { sp = orange,   undercurl = true })
hi(0, 'DiagnosticUnderlineInfo',    { sp = blue,     undercurl = true })
hi(0, 'DiagnosticUnderlineHint',    { sp = teal,     undercurl = true })
hi(0, 'LspReferenceText',           { bg = bg_alt })
hi(0, 'LspReferenceRead',           { bg = bg_alt })
hi(0, 'LspReferenceWrite',          { bg = bg_alt,   underline = true })

-- ============================================================
-- Git (gitsigns)
-- ============================================================
hi(0, 'GitSignsAdd',    { fg = green })
hi(0, 'GitSignsChange', { fg = orange })
hi(0, 'GitSignsDelete', { fg = red })
hi(0, 'DiffAdd',        { bg = '#d4edda' })
hi(0, 'DiffChange',     { bg = '#fff3cd' })
hi(0, 'DiffDelete',     { bg = '#f8d7da' })
hi(0, 'DiffText',       { bg = '#ffc680', bold = true })

-- ============================================================
-- Telescope
-- ============================================================
hi(0, 'TelescopeNormal',        { fg = fg,      bg = bg_alt })
hi(0, 'TelescopeBorder',        { fg = grey_ui, bg = bg_alt })
hi(0, 'TelescopeSelection',     { bg = '#c8d8ff', bold = true })
hi(0, 'TelescopeMatching',      { fg = orange,  bold = true })
hi(0, 'TelescopePromptPrefix',  { fg = blue,    bold = true })

-- ============================================================
-- Which-key
-- ============================================================
hi(0, 'WhichKey',          { fg = blue,    bold = true })
hi(0, 'WhichKeyGroup',     { fg = purple,  bold = true })
hi(0, 'WhichKeyDesc',      { fg = fg })
hi(0, 'WhichKeySeparator', { fg = comment })
hi(0, 'WhichKeyFloat',     { bg = bg_alt })
