class_name Money
extends RefCounted
## Whole naira, int64. Cap stays below JSON's exact integer boundary (2^53).
const LIMIT: int = 9000000000000000

static func rate(amount: int, basis_points: int) -> int:
	# Split before multiplication: no overflowing amount * rate intermediate.
	assert(amount >= 0 and amount <= LIMIT and basis_points >= 0 and basis_points <= 100000)
	@warning_ignore("integer_division")
	var value: int = (amount / 10000)*basis_points + ((amount % 10000)*basis_points)/10000
	return mini(LIMIT,value) # Percentages always round down to whole naira.

static func add(a: int, b: int) -> int:
	return mini(LIMIT,a+mini(b,LIMIT))
