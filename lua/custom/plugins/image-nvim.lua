return {
  '3rd/image.nvim',
  build = false, -- skip rock build, use magick_cli instead
  enabled = false,
  ft = { 'markdown', 'norg', 'typst' },
  -- event = { 'BufReadPre *.png,*.jpg,*.jpeg,*.gif,*.webp,*.avif' },
  opts = {
    backend = 'kitty',
    processor = 'magick_cli',
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { 'markdown' },
      },
    },
    max_width_window_percentage = 100,
    max_height_window_percentage = 50,
    hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' },
  },
}
