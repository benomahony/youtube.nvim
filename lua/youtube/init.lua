local M = {}

local config = {
	player_cmd = { "open" },
	cache_dir = nil,
	initial_results = 10,
	max_results = 100,
	background_delay = 500,
	keymap = "<leader>sy",
}

local function play_video(url)
	vim.fn.jobstart(vim.list_extend(vim.deepcopy(config.player_cmd), { url }), { detach = true })
end

local function parse_yt_line(line)
	if not line or line == "" then
		return nil
	end

	local parts = vim.split(line, "|", { plain = true })
	local title, uploader, url, id = parts[1], parts[2], parts[3], parts[4]

	if title and url and id and title ~= "" and url ~= "" and id ~= "" then
		return {
			title = title,
			uploader = uploader or "Unknown",
			url = url,
			id = id,
		}
	end
end

local function search_youtube(query, limit)
	limit = math.min(limit or config.initial_results, config.max_results)

	if vim.fn.executable("yt-dlp") == 0 then
		vim.notify("yt-dlp not found. Install with: brew install yt-dlp", vim.log.levels.ERROR)
		return {}
	end

	local cmd = string.format(
		"yt-dlp --flat-playlist --print '%%(title)s|%%(uploader)s|%%(webpage_url)s|%%(id)s' 'ytsearch%d:%s' 2>/dev/null",
		limit,
		query
	)

	local handle = io.popen(cmd)
	if not handle then
		vim.notify("Failed to search YouTube", vim.log.levels.ERROR)
		return {}
	end

	local results = {}
	for line in handle:lines() do
		local result = parse_yt_line(line)
		if result then
			table.insert(results, result)
		end
	end
	handle:close()
	return results
end

local function download_thumbnail_async(id, cache_dir, callback)
	local thumbnail_path = cache_dir .. "/" .. id .. ".jpg"

	if vim.fn.filereadable(thumbnail_path) == 1 then
		callback(thumbnail_path)
		return
	end

	local thumbnail_url = "https://img.youtube.com/vi/" .. id .. "/mqdefault.jpg"
	vim.fn.jobstart({ "curl", "-s", "-o", thumbnail_path, thumbnail_url }, {
		on_exit = function(_, code)
			vim.schedule(function()
				callback(code == 0 and vim.fn.filereadable(thumbnail_path) == 1 and thumbnail_path or nil)
			end)
		end,
	})
end

local function create_picker_items_async(results, cache_dir, callback)
	if #results == 0 then
		callback({})
		return
	end

	local picker_items = {}
	local completed = 0

	for i, result in ipairs(results) do
		download_thumbnail_async(result.id, cache_dir, function(thumbnail_path)
			picker_items[i] = {
				text = result.title .. " - " .. result.uploader,
				url = result.url,
				id = result.id,
				file = thumbnail_path,
			}

			completed = completed + 1
			if completed == #results then
				callback(picker_items)
			end
		end)
	end
end

local function create_youtube_picker(query, initial_results)
	local cache_dir = config.cache_dir or (vim.fn.stdpath("cache") .. "/youtube_thumbnails")
	vim.fn.mkdir(cache_dir, "p")

	create_picker_items_async(initial_results, cache_dir, function(picker_items)
		local picker = require("snacks.picker").pick({
			items = picker_items,
			format = function(item)
				return { { item.text, "Normal" } }
			end,
			confirm = function(picker, item)
				if item and item.url then
					play_video(item.url)
					picker:close()
				end
			end,
		})

		-- Background load more results
		vim.defer_fn(function()
			if picker and not picker.closed then
				vim.fn.jobstart({
					"yt-dlp",
					"--flat-playlist",
					"--print",
					"%(title)s|%(uploader)s|%(webpage_url)s|%(id)s",
					string.format("ytsearch%d:%s", config.max_results, query),
				}, {
					stdout_buffered = true,
					on_stdout = function(_, data)
						if picker and not picker.closed then
							local more_results = {}
							for _, line in ipairs(data or {}) do
								local result = parse_yt_line(line)
								if result then
									table.insert(more_results, result)
								end
							end

							if #more_results > #initial_results then
								picker:close()
								create_picker_items_async(more_results, cache_dir, function(new_picker_items)
									require("snacks.picker").pick({
										items = new_picker_items,
										format = function(item)
											return { { item.text, "Normal" } }
										end,
										confirm = function(picker, item)
											if item and item.url then
												play_video(item.url)
												picker:close()
											end
										end,
									})
									vim.notify(
										string.format("Loaded %d results", #more_results),
										vim.log.levels.INFO,
										{ timeout = 2000 }
									)
								end)
							end
						end
					end,
				})
			end
		end, config.background_delay)
	end)
end

function M.search()
	vim.ui.input({ prompt = "YouTube search: " }, function(query)
		if not query or query == "" then
			return
		end

		local results = search_youtube(query, config.initial_results)
		if #results == 0 then
			vim.notify("No results found - opening YouTube search in browser", vim.log.levels.WARN)
			local search_url = "https://www.youtube.com/results?search_query=" .. query:gsub(" ", "+")
			play_video(search_url)
			return
		end

		create_youtube_picker(query, results)
	end)
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	vim.api.nvim_create_user_command("YouTube", M.search, {})

	if config.keymap then
		vim.keymap.set("n", config.keymap, M.search, { desc = "Search YouTube" })
	end
end

return M
