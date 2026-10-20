class_name EconomyManager
extends Node
## All economic mutations pass through this single durable state owner.
signal changed
signal notice(message: String)

const SAVE_VERSION = 1
const DAY_SECONDS = 480.0
const LIMIT = 1000000000000
var save_path = "user://empire-save.json"
var state: Dictionary = {}
var last_error = ""
var volatile = false # Test-only switch; production always writes before announcing success.

func _ready() -> void:
	state = defaults()

func defaults() -> Dictionary:
	return {"cash":25000,"bank":0,"debt":0,"income":0,"expenses":0,
		"day":1,"clock":160.0,"seed":279,"reputation":0,"job_serial":0,"completed":0,
		"vehicles":{},"properties":{"home":0},"businesses":{},"shares":{},
		"prices":{"PALM":800,"LAGO":1600,"KORA":2400},"goods":0,"mission":{},
		"tutorial":0,"achievements":[],"recovery_day":-7,"fuel_price":80,"demand":1.0,
		"event":"Welcome to Lagos. Your first opportunity is at Oja Dispatch.",
		"position":[-25.0,0.2,9.0],"yaw":0.0,"interior":"","selected_vehicle":"",
		"settings":{"graphics":"Medium","audio":true},"ledger":[]}

func new_game() -> bool:
	var old = state.duplicate(true)
	state = defaults()
	return _commit(old,"Your story begins with ₦25,000. Visit Oja Dispatch.")

func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data = parser.data
	if not data is Dictionary or data.get("version",0) != SAVE_VERSION or not data.get("state") is Dictionary:
		return {}
	var s: Dictionary = data.state
	if not valid(s):
		return {}
	# JSON numbers decode as floats. Restore integer financial quantities explicitly.
	var schema = defaults()
	for key in schema:
		if schema[key] is int: s[key] = int(s[key])
	for field in ["properties","businesses","shares","prices"]:
		for key in s[field]: s[field][key] = int(s[field][key])
	if not s.mission.is_empty():
		s.mission.id = int(s.mission.id)
		s.mission.template = int(s.mission.template)
	return s

func load_game() -> bool:
	var data = _read(save_path)
	if data.is_empty():
		data = _read(save_path+".bak")
		if not data.is_empty():
			notice.emit("Recovered the previous save backup.")
	if data.is_empty():
		last_error = "No valid saved game. Start a new game."
		return false
	state = data
	changed.emit()
	return true

func _number(v: Variant, minimum: float, maximum: float) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) >= minimum and float(v) <= maximum

func _whole(v: Variant, minimum: int, maximum: int) -> bool:
	return _number(v,minimum,maximum) and floor(float(v)) == float(v)

func valid(s: Dictionary) -> bool:
	for key in defaults():
		if not s.has(key):
			return false
	for key in ["cash","bank","debt","income","expenses","reputation","job_serial","completed","goods","tutorial"]:
		if not _whole(s[key],0,LIMIT):
			return false
	if not _whole(s.day,1,1000000) or not _number(s.clock,0,DAY_SECONDS) or not _whole(s.seed,0,LIMIT):
		return false
	if not _whole(s.recovery_day,-7,1000000) or not _whole(s.fuel_price,30,200) or not _number(s.demand,0.5,1.5):
		return false
	if not s.position is Array or s.position.size() != 3 or not s.interior in ["","home","mansion"]:
		return false
	for v in s.position:
		if not _number(v,-1000,1000):
			return false
	if not _number(s.yaw,-1000000,1000000) or not s.selected_vehicle in ["","sedan","suv"]:
		return false
	for field in ["vehicles","properties","businesses","shares","prices","mission","settings"]:
		if not s[field] is Dictionary:
			return false
	for key in s.vehicles:
		if not Catalog.VEHICLES.has(key) or not s.vehicles[key] is Dictionary:
			return false
		for metric in ["fuel","condition"]:
			if not _number(s.vehicles[key].get(metric),0,100):
				return false
	for key in s.properties:
		if not Catalog.PROPERTIES.has(key) or not _whole(s.properties[key],0,3):
			return false
	if not s.properties.has("home"):
		return false
	for key in s.businesses:
		if not Catalog.BUSINESSES.has(key) or not _whole(s.businesses[key],1,12):
			return false
	for key in s.shares:
		if not Catalog.STOCKS.has(key) or not _whole(s.shares[key],0,100000000):
			return false
	for key in Catalog.STOCKS:
		if not _whole(s.prices.get(key),25,10000000):
			return false
	if not s.mission.is_empty():
		if not _whole(s.mission.get("template"),0,Catalog.JOBS.size()-1) or not _whole(s.mission.get("id"),1,LIMIT):
			return false
		if not _number(s.mission.get("remaining"),0,360):
			return false
	if not s.achievements is Array or not s.ledger is Array or s.ledger.size() > 30:
		return false
	for a in s.achievements:
		if not a is String:
			return false
	if not s.event is String or not s.settings.get("graphics") in ["Low","Medium","High"] or not s.settings.get("audio") is bool:
		return false
	return true

func save_game() -> bool:
	if not valid(state):
		last_error = "Save rejected: invalid game state."
		return false
	if volatile:
		return true
	var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "Storage unavailable; transaction cancelled."
		return false
	file.store_string(JSON.stringify({"version":SAVE_VERSION,"state":state},"",true,true))
	file.flush()
	var err = file.get_error()
	file.close()
	if err != OK:
		last_error = "Could not write save; transaction cancelled."
		return false
	# Only replace the backup with a validated save. Never back up corrupt input.
	if not _read(save_path).is_empty():
		if DirAccess.copy_absolute(save_path,save_path+".bak") != OK:
			last_error = "Could not back up save; transaction cancelled."
			return false
	if DirAccess.rename_absolute(save_path+".tmp",save_path) != OK:
		last_error = "Could not finalize save; transaction cancelled."
		return false
	return true

func _commit(old: Dictionary, message: String) -> bool:
	if not save_game():
		state = old
		notice.emit(last_error)
		return false
	changed.emit()
	if not message.is_empty():
		notice.emit(message)
	return true

func reject(message: String) -> bool:
	last_error = message
	notice.emit(message)
	return false

func _log(text: String) -> void:
	state.ledger.push_front("Day %d • %s" % [state.day,text])
	if state.ledger.size() > 30:
		state.ledger.pop_back()

func _spend(amount: int, reason: String) -> bool:
	if amount < 0 or amount > state.cash:
		return false
	state.cash -= amount
	state.expenses += amount
	_log(reason+" −"+Catalog.naira(amount))
	return true

func _earn(amount: int, reason: String) -> void:
	state.cash += amount
	state.income += amount
	_log(reason+" +"+Catalog.naira(amount))

func transfer(amount: int, deposit: bool) -> bool:
	if amount <= 0 or amount > (state.cash if deposit else state.bank):
		return reject("Insufficient funds for this transfer.")
	var old = state.duplicate(true)
	state.cash += -amount if deposit else amount
	state.bank += amount if deposit else -amount
	return _commit(old,"Transfer complete.")

func borrow(amount: int) -> bool:
	if amount <= 0 or state.debt+amount > 100000:
		return reject("Credit limit: ₦100,000 total debt. Interest is 2% daily.")
	var old = state.duplicate(true)
	state.debt += amount
	state.cash += amount
	_log("Loan "+Catalog.naira(amount))
	return _commit(old,"Loan received. Repay early to reduce daily interest.")

func repay(amount: int) -> bool:
	amount = mini(amount,int(state.debt))
	if amount <= 0 or amount > state.cash:
		return reject("No affordable repayment available.")
	var old = state.duplicate(true)
	_spend(amount,"Debt repayment")
	state.debt -= amount
	return _commit(old,"Debt reduced.")

func purchase(category: String, id: String) -> bool:
	var registry: Dictionary
	var owned: Dictionary
	match category:
		"vehicles": registry = Catalog.VEHICLES; owned = state.vehicles
		"properties": registry = Catalog.PROPERTIES; owned = state.properties
		"businesses": registry = Catalog.BUSINESSES; owned = state.businesses
		_: return reject("Unknown asset category.")
	if not registry.has(id) or owned.has(id):
		return reject("Asset unavailable or already owned.")
	var old = state.duplicate(true)
	if not _spend(registry[id].price,registry[id].name):
		return reject("You need "+Catalog.naira(registry[id].price)+" in your wallet.")
	match category:
		"vehicles": owned[id] = {"fuel":100.0,"condition":100.0}
		"properties": owned[id] = 0
		"businesses": owned[id] = 1
	_check_milestones()
	return _commit(old,"Purchased "+registry[id].name+".")

func upgrade(category: String, id: String) -> bool:
	if not category in ["businesses","properties"] or not state[category].has(id):
		return reject("Purchase this asset first.")
	var level = int(state[category][id])
	if level >= (12 if category == "businesses" else 3):
		return reject("Maximum upgrade reached.")
	var cost = upgrade_price(category,id)
	var old = state.duplicate(true)
	if not _spend(cost,"Asset upgrade"):
		return reject("Upgrade requires "+Catalog.naira(cost)+".")
	state[category][id] += 1
	return _commit(old,"Upgrade complete. Your empire is growing.")

func upgrade_price(category: String, id: String) -> int:
	var level = int(state[category].get(id,0))
	return int(Catalog.BUSINESSES[id].price*pow(2.2,level)) if category == "businesses" else int(Catalog.PROPERTIES[id].upgrade*(level+1))

func sell_asset(category: String, id: String) -> bool:
	if not category in ["vehicles","properties","businesses"] or not state[category].has(id) or id == "home":
		return reject("This asset cannot be sold.")
	var value = asset_value(category,id)
	var old = state.duplicate(true)
	state[category].erase(id)
	if category == "vehicles" and state.selected_vehicle == id:
		state.selected_vehicle = ""
	if category == "properties" and state.interior == id:
		state.interior = ""
		state.position = [83.0,0.2,-84.0]
	_earn(value,"Asset sale")
	return _commit(old,"Asset sold for "+Catalog.naira(value)+".")

func asset_value(category: String, id: String) -> int:
	match category:
		"vehicles": return int(Catalog.VEHICLES[id].price*0.7*state.vehicles[id].condition/100)
		"properties": return int(Catalog.PROPERTIES[id].price*0.8+Catalog.PROPERTIES[id].upgrade*state.properties[id]*0.5)
		"businesses": return int(Catalog.BUSINESSES[id].price*pow(2.1,state.businesses[id]-1)*0.7)
	return 0

func net_worth() -> int:
	var total = int(state.cash+state.bank-state.debt+state.goods*700)
	for category in ["vehicles","properties","businesses"]:
		for id in state[category]:
			total += asset_value(category,id)
	for id in state.shares:
		total += int(state.shares[id]*state.prices[id])
	return total

func stock(id: String, quantity: int, buy: bool) -> bool:
	if not Catalog.STOCKS.has(id) or quantity <= 0 or quantity > 100000:
		return reject("Invalid investment order.")
	var amount = int(state.prices[id])*quantity
	var fee = maxi(1,int(ceil(amount*0.01)))
	if not buy and state.shares.get(id,0) < quantity:
		return reject("You do not own that many shares.")
	var old = state.duplicate(true)
	if buy:
		if not _spend(amount+fee,"Buy "+id):
			return reject("Insufficient cash, including the 1% transaction fee.")
		state.shares[id] = state.shares.get(id,0)+quantity
	else:
		state.shares[id] -= quantity
		_earn(amount-fee,"Sell "+id)
	_check_milestones()
	return _commit(old,"Investment order filled. Prices can rise or fall.")

func trade(buy: bool, quantity: int, location: String) -> bool:
	if quantity <= 0 or quantity > 20:
		return reject("Trade between 1 and 20 crates at a time.")
	if (buy and location != "market") or (not buy and location != "cafe"):
		return reject("Buy at Ayo Market; sell at Suya Junction.")
	if (buy and state.goods+quantity > 20) or (not buy and state.goods < quantity):
		return reject("Check your cargo. Capacity: 20 crates.")
	var old = state.duplicate(true)
	if buy:
		if not _spend(quantity*700,"Wholesale crates"):
			return reject("Not enough cash for these goods.")
		state.goods += quantity
	else:
		state.goods -= quantity
		_earn(quantity*int(1100*state.demand),"Market sale")
	return _commit(old,"Trade complete.")

func accept_job(index: int, position: Vector3) -> bool:
	if index < 0 or index >= Catalog.JOBS.size() or position.distance_to(Catalog.LOCATIONS.work.pos) > 6:
		return reject("Visit Oja Dispatch to collect a job.")
	if not state.mission.is_empty():
		return reject("Finish or cancel your current job first.")
	var old = state.duplicate(true)
	state.job_serial += 1
	state.mission = {"id":state.job_serial,"template":index,"remaining":Catalog.JOBS[index].seconds}
	state.tutorial = maxi(1,state.tutorial)
	return _commit(old,"Job accepted. Follow the gold waypoint." + (" Use the yellow company car." if Catalog.JOBS[index].type == "driving" else ""))

func complete_job(position: Vector3, in_car: bool) -> bool:
	if state.mission.is_empty():
		return reject("No active job.")
	var job: Dictionary = Catalog.JOBS[int(state.mission.template)]
	if state.mission.remaining <= 0 or position.distance_to(Catalog.LOCATIONS[job.target].pos) > 6:
		return reject("Reach the destination before the deadline.")
	if job.type == "driving" and not in_car:
		return reject("Bring your passenger in a vehicle.")
	var old = state.duplicate(true)
	state.mission = {} # Consumed in the same durable commit as the reward.
	state.completed += 1
	state.reputation += 5
	_earn(job.pay,"Job complete")
	if state.tutorial < 2:
		state.tutorial = 2
		_earn(2500,"First mile bonus")
	_check_milestones()
	return _commit(old,"Job complete! Earned "+Catalog.naira(job.pay)+".")

func cancel_job() -> bool:
	var old = state.duplicate(true)
	state.mission = {}
	return _commit(old,"Job cancelled. No reward paid.")

func service(id: String, refuel: bool) -> bool:
	if not state.vehicles.has(id):
		return reject("Select an owned vehicle.")
	var metric = "fuel" if refuel else "condition"
	var cost = int(ceil((100-state.vehicles[id][metric])*(state.fuel_price if refuel else 110)))
	if cost == 0:
		return reject("Already in excellent condition.")
	var old = state.duplicate(true)
	if not _spend(cost,"Fuel" if refuel else "Repairs"):
		return reject("Service requires "+Catalog.naira(cost)+".")
	state.vehicles[id][metric] = 100.0
	return _commit(old,"Vehicle serviced.")

func recover() -> bool:
	if state.cash+state.bank >= 5000 or state.day-state.recovery_day < 7:
		return reject("Emergency grant: available below ₦5,000 liquid funds, once every 7 days.")
	var old = state.duplicate(true)
	state.recovery_day = state.day
	_earn(5000,"Community recovery grant")
	return _commit(old,"₦5,000 recovery grant received. Walking deliveries remain available.")

func tick(delta: float) -> void:
	state.clock += delta
	if not state.mission.is_empty():
		state.mission.remaining = maxf(0,state.mission.remaining-delta)
		if state.mission.remaining <= 0:
			var old = state.duplicate(true)
			state.mission = {}
			_commit(old,"Deadline missed. Collect another job at Oja Dispatch.")
	if state.clock >= DAY_SECONDS:
		state.clock = DAY_SECONDS # rollback remains valid on storage failure
		advance_day()

func _bill(amount: int, reason: String) -> void:
	var paid = mini(int(state.cash),amount)
	_spend(paid,reason)
	state.debt += amount-paid
	if amount > paid:
		_log("Unpaid "+reason+" added to debt: "+Catalog.naira(amount-paid))

func advance_day() -> bool:
	var old = state.duplicate(true)
	state.day += 1
	state.clock = 0.0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(state.seed)+int(state.day)*7919
	state.demand = rng.randf_range(0.8,1.25)
	state.fuel_price = rng.randi_range(60,110)
	state.event = "Demand %d%% • fuel ₦%d/unit" % [int(state.demand*100),state.fuel_price]
	for id in Catalog.STOCKS:
		var info: Dictionary = Catalog.STOCKS[id]
		var reversion = clampf((float(info.base)/state.prices[id]-1)*0.03,-0.03,0.03)
		var change = 0.002+reversion+rng.randf_range(-info.volatility,info.volatility)
		state.prices[id] = clampi(int(round(state.prices[id]*(1+change))),25,10000000)
	for id in state.businesses:
		var scale = pow(2.1,state.businesses[id]-1)
		_earn(int(Catalog.BUSINESSES[id].revenue*scale*state.demand),Catalog.BUSINESSES[id].name)
		_bill(int(Catalog.BUSINESSES[id].cost*scale),"Business operations")
		if rng.randf() < 0.18:
			var setback = int(2000*scale)
			_bill(setback,"Unexpected business repairs")
			state.event += " • repairs "+Catalog.naira(setback)
	if not state.properties.has("mansion"):
		_bill(1200,"Room rent")
	if state.debt > 0:
		state.debt += maxi(1,int(ceil(state.debt*0.02)))
	if int(state.day)%7 == 0:
		_earn(int(state.bank*0.005),"Weekly bank interest")
	_check_milestones()
	return _commit(old,"Day %d • %s" % [state.day,state.event])

func _check_milestones() -> void:
	for milestone in [100000,1000000,10000000,100000000,1000000000]:
		var key = str(milestone)
		if net_worth() >= milestone and not state.achievements.has(key):
			state.achievements.append(key)
			state.reputation += 25
			_earn(int(milestone*0.01),"Milestone reward")
	if state.vehicles.has("sedan") and state.tutorial < 3 and state.completed > 0:
		state.tutorial = 3
		_earn(5000,"Intro quest complete")
