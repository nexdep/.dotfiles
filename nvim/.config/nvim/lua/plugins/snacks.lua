return {
	{
		"folke/snacks.nvim",
		opts = {
			words = {
				enabled = true,
			        },
			picker = {
				hidden = true,   -- show files starting with “.”
				ignored = true,  -- include files matched by .gitignore
				sources = {
					  files = {
						    hidden  = true,
						    ignored = true,
						  },
					},
			      },
			},
	},
}
