class_name EconomicSimulationManager
extends RefCounted
## Scheduled once per game day. Prices follow causes, with bounded seeded noise.
static var sectors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sectors.json"))

static func defaults() -> Dictionary:
	return {"cycle":"Expansion","spending":10000,"inflation":10000,"property_index":10000,
		"fuel_index":10000,"supply":10000,"competition":{},"last_day":1,"event_until":0,
		"event_kind":"steady","news":[],"history":[],"reports":{},
		"rivals":[{"name":"Bisi Adewale","sector":"retail","strategy":"Quality","wealth":180000,"debt":0,"strength":350,"relationship":0},
		{"name":"Tunde Bello","sector":"logistics","strategy":"Undercut","wealth":320000,"debt":50000,"strength":700,"relationship":0},
		{"name":"Amara Okoye","sector":"property","strategy":"Patient","wealth":600000,"debt":0,"strength":250,"relationship":0}]}

static func step(s: Dictionary) -> void:
	var sim: Dictionary = s.simulation
	if int(sim.last_day) >= int(s.day): return
	var rng = RandomNumberGenerator.new()
	rng.seed = int(s.seed)+int(s.day)*7919
	var wave = sin((float(s.day)+int(s.seed)%120)*TAU/120.0)
	sim.cycle = "Expansion" if wave > 0.25 else ("Recession" if wave < -0.25 else "Recovery")
	sim.spending = clampi(10000+int(wave*2200)+rng.randi_range(-250,250),7500,12500)
	# Inflation index is bounded: this is a game economy, not unlimited compounding.
	sim.inflation = clampi(10000+int(s.day)%365*3+int(wave*300),9500,11500)
	sim.fuel_index = clampi(10000+int(sin(float(s.day)/17.0)*1200)+int(wave*500),8000,15000)
	sim.supply = 10000
	if s.day > sim.event_until:
		sim.event_kind = "steady"
		if int(s.day)%9 == 0:
			sim.event_kind = ["rain","shortage","festival","infrastructure"][rng.randi_range(0,3)]
			sim.event_until = int(s.day)+2
	match sim.event_kind:
		"rain": sim.fuel_index += 1500
		"shortage": sim.supply = 8200
		"festival": sim.spending = mini(14000,sim.spending+1800)
		"infrastructure": sim.fuel_index = maxi(7000,sim.fuel_index-1000)
	sim.property_index = clampi(10000+int(wave*1800)+(sim.spending-10000)/3,7000,14000)
	sim.competition = {}
	for rival in sim.rivals:
		var pressure = 1 if sim.spending > 10000 else -1
		rival.strength = clampi(int(rival.strength)+pressure*(20 if rival.strategy == "Undercut" else 10),150,1800)
		if s.businesses.has("logistics") and rival.strategy == "Undercut": rival.strength = mini(1800,rival.strength+15)
		rival.wealth = clampi(int(rival.wealth)+pressure*1500,25000,50000000)
		rival.debt = maxi(0,int(rival.debt)+(500 if pressure < 0 else -500))
		sim.competition[rival.sector] = int(rival.strength)
	s.fuel_price = Money.rate(80,int(sim.fuel_index))
	s.demand = clampf(float(sim.spending)/10000,0.5,1.5)
	var cause = {"steady":"Consumer spending follows the business cycle.","rain":"Heavy rain raises transport costs for three days.","shortage":"Inventory shortages constrain sales for three days.","festival":"Festival visitors increase customer spending for three days.","infrastructure":"Road improvements lower transport costs for three days."}[sim.event_kind]
	s.event = "%s • spending %d%% • fuel ₦%d. %s" % [sim.cycle,sim.spending/100,s.fuel_price,cause]
	sim.news.push_front("Day %d: %s" % [s.day,s.event])
	if sim.news.size() > 20: sim.news.pop_back()
	for id in Catalog.STOCKS:
		var info: Dictionary = Catalog.STOCKS[id]
		var sector = {"PALM":"retail","LAGO":"logistics","KORA":"mobility"}[id]
		var fundamental = Money.rate(int(info.base),int(sim.spending))
		if id == "LAGO": fundamental = Money.rate(fundamental,int(sim.fuel_index))
		var reversion = clampi(int((fundamental-int(s.prices[id]))*250/maxi(25,int(s.prices[id]))),-350,350)
		var noise = rng.randi_range(-int(info.volatility*10000),int(info.volatility*10000))
		var change = reversion+noise+int((sim.spending-10000)/30)-int(sim.competition.get(sector,0)/30)
		s.prices[id] = clampi(Money.rate(int(s.prices[id]),10000+change),25,10000000)
	sim.last_day = s.day

static func business_report(s: Dictionary, id: String) -> Dictionary:
	var info: Dictionary = Catalog.BUSINESSES[id]
	var sim: Dictionary = s.simulation
	var level = int(s.businesses.get(id,1))
	var sector: Dictionary = sectors[info.sector]
	var capacity = 10000+(level-1)*6000
	var competition = int(sim.competition.get(info.sector,0))
	var skill = mini(1000,int(s.skills.management)*10)
	var demand = clampi(10000+int((sim.spending-10000)*sector.spending_sensitivity/10000)-competition,5500,14000)
	var gross = Money.rate(Money.rate(int(info.revenue),capacity),demand)
	gross = Money.rate(gross,int(sim.supply))
	var costs = Money.rate(int(info.cost),capacity)
	costs = Money.rate(costs,clampi(int(sim.inflation)+int((sim.fuel_index-10000)*sector.fuel_sensitivity/10000)-skill,8500,15000))
	return {"revenue":gross,"cost":costs,"profit":gross-costs,"salaries":Money.rate(costs,4500),"capacity":capacity,"demand":demand,"competition":competition,"efficiency":10000+skill}
