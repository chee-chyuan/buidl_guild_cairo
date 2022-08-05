%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_sqrt

@view
func test_stuff{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    let x = Uint256(11,0)
    let (sqrt_x) = uint256_sqrt(x)

    %{
        print(f"low: {ids.sqrt_x.low}")
        print(f"high: {ids.sqrt_x.high}")
    %}

    return ()
end