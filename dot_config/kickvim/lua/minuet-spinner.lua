local M = {}

M.state = {
  status = 'idle', -- idle | pending | error
  spinner = 1,
  timer = nil,
}

local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local function start_spinner()
  M.state.status = 'pending'
  if M.state.timer then
    return
  end
  M.state.timer = vim.uv.new_timer()
  M.state.timer:start(0, 100, function()
    M.state.spinner = (M.state.spinner % #spinner_frames) + 1
    vim.schedule(function()
      vim.cmd 'redrawstatus'
    end)
  end)
end

local function stop_spinner()
  if M.state.timer then
    M.state.timer:stop()
    M.state.timer:close()
    M.state.timer = nil
  end
  M.state.spinner = 1
end

function M.setup()
  local group = vim.api.nvim_create_augroup('minuet_spinner', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'MinuetRequestStartedPre',
    callback = function()
      M.state.status = 'pending'
      start_spinner()
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'MinuetRequestFinished',
    callback = function()
      stop_spinner()
      -- Keep pending status briefly so the spinner shows the final state
      -- If an error occurred, minuet will have notified it; we detect
      -- errors by intercepting vim.notify for minuet messages (see below)
      vim.defer_fn(function()
        if M.state.status == 'pending' then
          M.state.status = 'idle'
        end
      end, 100)
    end,
  })

  -- Intercept minuet error notifications to show error state
  local original_notify = vim.notify
  vim.notify = function(msg, level, opts)
    if type(msg) == 'string' and (msg:find('[Mm]inuet') or msg:find('Request timed out') or msg:find('Request failed')) then
      if level and level >= vim.log.levels.WARN then
        M.state.status = 'error'
        vim.defer_fn(function()
          if M.state.status == 'error' then
            M.state.status = 'idle'
          end
        end, 3000)
      end
    end
    return original_notify(msg, level, opts)
  end
end

function M.component()
  if M.state.status == 'pending' then
    return spinner_frames[M.state.spinner] .. ' minuet'
  elseif M.state.status == 'error' then
    return ' minuet error'
  end
  return ''
end

return M