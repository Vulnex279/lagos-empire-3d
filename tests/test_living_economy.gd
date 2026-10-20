extends SceneTree
var e: Node
var failures = 0
var checks = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: "+label)
	else: print("PASS: "+label)

func run() -> void:
	e = root.get_node("Economy")
	e.volatile = true
	check(Money.rate(10000000000000,125) == 125000000000,"₦10 trillion basis-point rounding stays exact")
	check(Money.rate(Money.LIMIT,100000) == Money.LIMIT,"Maximum multiplication saturates without overflow")
	e.state = e.defaults()
	e.state.cash = 10000000000000
	check(e.transfer(7000000000000,true) and e.state.bank == 7000000000000,"Multi-trillion transfer conserves balances")
	check(e.purchase("businesses","holding"),"Late-game holding company is purchasable")
	check(e.advance_day() and e.valid(e.state),"Large business daily settlement remains valid")
	e.state = e.defaults()
	e.state.cash = 5000000
	check(e.purchase("vehicles","sports"),"Sports car purchase")
	check(e.sell_asset("vehicles","sports") and not e.sell_asset("vehicles","sports"),"Same vehicle cannot be sold twice")
	check(not e.purchase("properties","commercial"),"Unaffordable property rejected")
	e.state = e.defaults()
	var once = e.state.simulation.duplicate(true)
	EconomicSimulationManager.step(e.state)
	check(e.state.simulation == once,"Duplicate same-day market tick is ignored")
	var offers: Array = e.job_offers()
	check(not e.accept_job(9,Catalog.LOCATIONS.work.pos),"Trust blocks premium contracts")
	for i in 4:
		e.accept_job(0,Catalog.LOCATIONS.work.pos)
		e.complete_job(Catalog.LOCATIONS.bank.pos,false)
	check(e.accept_job(9,Catalog.LOCATIONS.work.pos),"Completed contracts unlock trust-gated opportunity")
	var offer = e.active_job().duplicate(true)
	check(e.complete_job(Catalog.LOCATIONS[offer.target].pos,false),"Generated express contract pays at actual target")
	var paid = e.state.cash
	check(not e.complete_job(Catalog.LOCATIONS[offer.target].pos,false) and e.state.cash == paid,"Generated contract cannot pay twice")
	e.state.cash = 200000
	e.purchase("businesses","mart")
	check(e.accept_job(8,Catalog.LOCATIONS.work.pos),"Owned business unlocks supply contract")
	offer = e.active_job().duplicate(true)
	check(not e.complete_job(Catalog.LOCATIONS[offer.target].pos,false),"Supply contract requires physical cargo")
	e.trade(true,3,"market")
	check(e.complete_job(Catalog.LOCATIONS[offer.target].pos,false) and e.state.goods == 0,"Supply contract consumes crates atomically")
	var varied = {}
	for day in range(1,12):
		e.state.day = day
		var jobs: Array = e.job_offers()
		check(jobs == e.job_offers(),"Offers deterministic within day %d" % day)
		for job in jobs:
			check(e._valid_job(job),"Generated/authored job validates")
			varied[str(job)] = true
	check(varied.size() > 20,"Mission contexts produce varied valid offers")
	e.state = e.defaults()
	e.state.cash = 0
	e.state.debt = 100000
	check(e.bankrupt() and e.state.cash == 5000 and e.state.debt == 0,"Insolvency clears debt and funds recovery")
	check(not e.bankrupt(),"Insolvency cannot be farmed")
	check(e.accept_job(0,Catalog.LOCATIONS.work.pos) and e.complete_job(Catalog.LOCATIONS.bank.pos,false),"Work accessible after bankruptcy")
	# Real disk round trip, migration, interrupted write and bounded corrupted data.
	e.volatile = false
	e.save_path = "user://living-tests.json"
	e.state.cash = 10000000000000
	e.state.bank = 2345678901234
	check(e.save_game(),"Trillion-value save writes")
	var snapshot = e.state.duplicate(true)
	check(e.load_game() and e.state == snapshot,"Full rich state and exact large integers survive disk round trip")
	var file = FileAccess.open(e.save_path+".tmp",FileAccess.WRITE)
	file.store_string("interrupted");file.close()
	check(e.load_game() and e.state == snapshot,"Interrupted temporary save leaves primary intact")
	var original_keys = ["cash","bank","debt","income","expenses","day","clock","seed","reputation","job_serial","completed","vehicles","properties","businesses","shares","prices","goods","mission","tutorial","achievements","recovery_day","fuel_price","demand","event","position","yaw","interior","selected_vehicle","settings","ledger"]
	var legacy = e.defaults()
	for key in legacy.keys():
		if not key in original_keys: legacy.erase(key)
	legacy.cash = 78901
	file = FileAccess.open(e.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"state":legacy}));file.close()
	check(e.load_game() and e.state.cash == 78901 and e.state.simulation.last_day == 1,"Version-one save migrates without resetting cash")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(e.save_path+suffix): DirAccess.remove_absolute(e.save_path+suffix)
	e.volatile = true
	var loss_days = 0
	var profit_days = 0
	for seed_value in [1,279,8407,99991]:
		e.state = e.defaults()
		e.state.seed = seed_value
		e.state.cash = 1000000
		e.state.businesses = {"mart":1,"logistics":1,"restaurant":1}
		e.state.properties.apartment = 0
		var initial = e.state.duplicate(true)
		var first_month = {}
		var all_valid = true
		for day in 3000:
			if not e.advance_day() or not e.valid(e.state): all_valid = false; break
			for report in e.state.simulation.reports.values():
				if report.profit < 0: loss_days += 1
				else: profit_days += 1
			if day == 29: first_month = e.state.duplicate(true)
		check(all_valid,"3,000 simulated days retain financial invariants, seed %d" % seed_value)
		print("BALANCE seed=",seed_value," cash=",e.state.cash," debt=",e.state.debt," worth=",e.net_worth())
		check(e.state.simulation.history.size() == 60 and e.state.simulation.news.size() == 20,"History storage stays bounded")
		e.state = initial
		for day in 30: e.advance_day()
		check(e.state == first_month,"Identical seed/input replays exact economic state")
	check(loss_days > 0 and profit_days > loss_days,"Cycles produce both profitable and loss-making business days")
	e.state = e.defaults()
	e.borrow(25000)
	e.advance_day()
	check(e.state.debt == 25500,"Loan interest rounds correctly: ₦25,000 becomes ₦25,500")
	e.state = e.defaults()
	e.accept_job(0,Catalog.LOCATIONS.work.pos)
	e.tick(e.DAY_SECONDS)
	check(e.state.day == 2 and e.state.mission.is_empty() and e.valid(e.state),"Resting across a mission deadline settles without invalid clock values")
	e.state = e.defaults()
	var debt_valid = true
	for day in 3000:
		if not e.advance_day(): debt_valid = false; break
	check(debt_valid and e.valid(e.state),"3,000 unemployed days cannot overflow accumulated debt")
	check(e.bankrupt() and e.state.debt == 0,"Recovery remains available after extreme accumulated debt")
	print("BALANCE profitable business-days=",profit_days," loss business-days=",loss_days)
	print("LIVING ECONOMY RESULTS: ",checks," checks, ",failures," failures; 15,000 simulated days including insolvency stress + deterministic replays")
	quit(1 if failures else 0)
