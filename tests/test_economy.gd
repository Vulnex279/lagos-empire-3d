extends SceneTree

var e: Node
var failures = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: "+message)
	else:
		print("PASS: "+message)

func run() -> void:
	e = root.get_node("Economy")
	e.save_path = "user://economy-test-save.json"
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(e.save_path+suffix): DirAccess.remove_absolute(e.save_path+suffix)
	check(e.new_game(),"New game saves successfully")
	check(e.state.cash == 25000 and e.net_worth() == 25000,"Starts with exactly ₦25,000")
	check(not e.purchase("vehicles","sedan"),"Unaffordable car rejected")
	check(e.state.cash == 25000,"Rejected purchase leaves balance unchanged")
	check(not e.transfer(-500,true),"Negative transfer rejected")
	check(e.transfer(5000,true) and e.state.bank == 5000 and e.state.cash == 20000,"Deposit conserves funds")
	check(e.transfer(5000,false) and e.state.cash == 25000,"Withdrawal conserves funds")
	check(not e.transfer(1,false),"Bank overdraft rejected")
	check(not e.accept_job(0,Vector3.ZERO),"Remote job pickup rejected")
	check(e.accept_job(0,Catalog.LOCATIONS.work.pos),"Mission pickup at workplace")
	check(not e.accept_job(1,Catalog.LOCATIONS.work.pos),"Only one active mission")
	check(not e.complete_job(Vector3.ZERO,false),"Remote completion rejected")
	check(e.complete_job(Catalog.LOCATIONS.bank.pos,false),"Delivery rewards valid destination")
	check(e.state.cash == 34000 and e.state.completed == 1,"First job reward and one-time bonus")
	check(not e.complete_job(Catalog.LOCATIONS.bank.pos,false),"Repeat completion cannot duplicate payout")
	check(e.load_game() and e.state.cash == 34000 and e.state.mission.is_empty(),"Reload preserves consumed reward")
	check(not e.complete_job(Catalog.LOCATIONS.bank.pos,false),"Reload cannot replay reward")
	check(e.accept_job(3,Catalog.LOCATIONS.work.pos),"Passenger job pickup")
	check(not e.complete_job(Catalog.LOCATIONS.waterfront.pos,false),"Passenger needs a vehicle")
	check(e.complete_job(Catalog.LOCATIONS.waterfront.pos,true),"Passenger arrival pays")
	check(e.purchase("vehicles","sedan"),"Earned funds buy first vehicle")
	check(e.state.tutorial == 3 and e.state.cash == 5000,"Intro quest completes and pays bonus once")
	check(not e.purchase("vehicles","sedan"),"Duplicate vehicle purchase rejected")
	check(e.accept_job(2,Catalog.LOCATIONS.work.pos),"Replayable job accepted")
	e.tick(101)
	check(e.state.mission.is_empty() and e.state.cash == 5000,"Expired mission gives no payout")
	check(not e.trade(true,5,"cafe"),"Wholesale restricted to market")
	check(e.trade(true,5,"market") and e.state.goods == 5,"Goods purchase")
	check(e.trade(false,5,"cafe") and e.state.goods == 0,"Goods sold at destination")
	check(not e.trade(false,5,"cafe"),"Cannot resell consumed cargo")
	check(e.stock("PALM",1,true),"Investment purchase")
	var cash_after_buy = e.state.cash
	check(e.stock("PALM",1,false) and e.state.cash == cash_after_buy+792,"Investment sell charges fee")
	check(not e.stock("PALM",1,false),"Short selling unsupported")
	check(not e.stock("PALM",-10,true),"Negative share quantity rejected")
	check(e.borrow(25000) and e.state.debt == 25000,"Loan creates matching debt")
	check(not e.borrow(100000),"Loan limit enforced")
	check(e.repay(5000) and e.state.debt == 20000,"Debt repayment")
	e.state.cash = 4000000
	check(e.purchase("properties","mansion"),"Mansion purchase")
	check(not e.purchase("properties","mansion"),"Duplicate property purchase rejected")
	check(e.upgrade("properties","mansion") and e.state.properties.mansion == 1,"Furniture upgrade")
	check(e.purchase("businesses","mart"),"Mini-mart purchase")
	check(e.purchase("businesses","logistics"),"Delivery company purchase")
	check(e.upgrade("businesses","mart"),"Business upgrade")
	var before_income = e.state.income
	var before_expense = e.state.expenses
	var before_prices = e.state.prices.duplicate()
	check(e.advance_day(),"Daily financial event commits")
	check(e.state.income > before_income and e.state.expenses > before_expense,"Business revenue and costs recorded")
	check(e.state.debt > 20000,"Daily debt interest applied")
	check(e.state.prices != before_prices,"Market prices move daily")
	var saved = e.state.duplicate(true)
	check(e.save_game() and e.load_game() and e.state == saved,"Full economy round-trip persistence")
	e.state = e.defaults()
	e.state.cash = 0
	check(e.advance_day() and e.state.cash == 0 and e.state.debt > 0,"Unpaid rent becomes debt without negative cash")
	check(e.recover() and e.state.cash == 5000,"Bankruptcy recovery grant")
	check(not e.recover(),"Recovery grant cannot be repeatedly claimed")
	check(e.accept_job(0,Catalog.LOCATIONS.work.pos) and e.complete_job(Catalog.LOCATIONS.bank.pos,false),"Walking work remains available while in debt")
	var invalid = e.state.duplicate(true)
	invalid.cash = -1
	check(not e.valid(invalid),"Negative cash in save rejected")
	invalid.cash = NAN
	check(not e.valid(invalid),"NaN cash in save rejected")
	invalid = e.state.duplicate(true)
	invalid.vehicles = {"fake":{"fuel":100,"condition":100}}
	check(not e.valid(invalid),"Unknown owned asset rejected")
	check(e.save_game(),"Save before corruption test")
	var f = FileAccess.open(e.save_path,FileAccess.WRITE)
	f.store_string("broken JSON")
	f.close()
	check(e.load_game(),"Corrupt primary recovers valid backup")
	var real_path = e.save_path
	e.save_path = "user://missing-directory/save.json"
	var old = e.state.duplicate(true)
	check(not e.borrow(1000) and e.state == old,"Storage failure rolls back financial transaction")
	e.save_path = real_path
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(e.save_path+suffix): DirAccess.remove_absolute(e.save_path+suffix)
	print("ECONOMY RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
