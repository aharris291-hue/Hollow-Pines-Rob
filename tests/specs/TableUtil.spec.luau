local TestKit = require("../TestKit")
local TableUtil = require("../../src/shared/Util/TableUtil")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("TableUtil.reconcile", function()
	it("adds missing keys from the template", function()
		local data = { Embers = 10 }
		TableUtil.reconcile(data, { Embers = 0, Level = 1, Settings = { Captions = true } })
		expect(data.Embers).toBe(10)
		expect(data.Level).toBe(1)
		expect(data.Settings.Captions).toBe(true)
	end)

	it("fills nested keys without touching existing ones", function()
		local data = { Settings = { Captions = false } }
		TableUtil.reconcile(data, { Settings = { Captions = true, TextScale = 1 } })
		expect(data.Settings.Captions).toBe(false)
		expect(data.Settings.TextScale).toBe(1)
	end)

	it("repairs values of the wrong type", function()
		local data = { Embers = "lots" }
		TableUtil.reconcile(data, { Embers = 0 })
		expect(data.Embers).toBe(0)
	end)

	it("keeps player-owned dictionary entries the template does not know", function()
		local data = { Owned = { Firefly = true } }
		TableUtil.reconcile(data, { Owned = { Flashlight = true } })
		expect(data.Owned.Firefly).toBe(true)
		expect(data.Owned.Flashlight).toBe(true)
	end)

	it("deep copies template tables", function()
		local template = { Owned = { Flashlight = true } }
		local data = TableUtil.reconcile({}, template)
		data.Owned.Extra = true
		expect(template.Owned.Extra).toBe(nil)
	end)
end)
