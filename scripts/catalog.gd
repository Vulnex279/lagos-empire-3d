class_name Catalog
extends RefCounted

const LOCATIONS = {
	"home": {"name": "Your rented room", "pos": Vector3(-25,0,12), "color": Color("e4b171")},
	"work": {"name": "Oja Dispatch • Jobs", "pos": Vector3(-25,0,-24), "color": Color("55c2aa")},
	"market": {"name": "Ayo Market • Trade", "pos": Vector3(25,0,24), "color": Color("e5b15d")},
	"dealer": {"name": "Eko Motors", "pos": Vector3(25,0,-24), "color": Color("77abc4")},
	"bank": {"name": "Harbour Community Bank", "pos": Vector3(-25,0,82), "color": Color("70b9b1")},
	"invest": {"name": "Marina Exchange", "pos": Vector3(25,0,82), "color": Color("b7a8d9")},
	"mart": {"name": "Your next mini-mart", "pos": Vector3(-83,0,-24), "color": Color("e5b15d")},
	"logistics": {"name": "Coastline Logistics", "pos": Vector3(83,0,25), "color": Color("55c2aa")},
	"mansion": {"name": "Palm Court Residence", "pos": Vector3(83,0,-82), "color": Color("ece3ce")},
	"garage": {"name": "Palm Court Garage", "pos": Vector3(103,0,-82), "color": Color("77abc4")},
	"cafe": {"name": "Suya Junction", "pos": Vector3(-83,0,82), "color": Color("dc875f")},
	"waterfront": {"name": "Lagoon promenade", "pos": Vector3(83,0,82), "color": Color("77abc4")}
}
const VEHICLES = {
	"sedan": {"name": "Kora Compact", "price": 45000, "speed": 24.0, "color": Color("40a99f")},
	"suv": {"name": "Oba Grand SUV", "price": 850000, "speed": 32.0, "color": Color("263a4f")}
}
const PROPERTIES = {
	"home": {"name": "Rented room", "price": 0, "rent": 1200, "upgrade": 8000},
	"mansion": {"name": "Palm Court mansion", "price": 2500000, "rent": 0, "upgrade": 180000}
}
const BUSINESSES = {
	"mart": {"name": "Neighbourhood mini-mart", "price": 90000, "revenue": 15000, "cost": 4500},
	"logistics": {"name": "Delivery company", "price": 240000, "revenue": 36000, "cost": 13000}
}
const STOCKS = {
	"PALM": {"name": "Palm Foods", "base": 800, "volatility": 0.06},
	"LAGO": {"name": "Lagoon Energy", "base": 1600, "volatility": 0.10},
	"KORA": {"name": "Kora Mobility", "base": 2400, "volatility": 0.14}
}
const JOBS = [
	{"name": "First mile • documents", "type": "delivery", "target": "bank", "pay": 6500, "seconds": 180},
	{"name": "Hot lunch • Suya Junction", "type": "delivery", "target": "cafe", "pay": 8500, "seconds": 180},
	{"name": "Market restock", "type": "delivery", "target": "market", "pay": 4500, "seconds": 100},
	{"name": "Lagoon passenger", "type": "driving", "target": "waterfront", "pay": 11000, "seconds": 150},
	{"name": "Marina commuter", "type": "driving", "target": "invest", "pay": 9500, "seconds": 140},
	{"name": "Palm Court express", "type": "delivery", "target": "mansion", "pay": 12500, "seconds": 130}
]

static func naira(value: int) -> String:
	var digits = str(absi(value))
	var result = ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return ("−₦" if value < 0 else "₦") + result
