%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_sqrt, uint256_mul, uint256_unsigned_div_rem
from starkware.starknet.common.syscalls import get_block_timestamp

@view
func test_stuff{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
   
    let MULTIPLIER_1_E_20 = Uint256(0x56bc75e2d63100000, 0)
    let start_time = 1650000000
    let end_time = 1660000000

    let diff = end_time - start_time
    tempvar denominator: Uint256 = Uint256(diff,0)

    let time_now = 1651000000
    let diff = time_now - start_time
    tempvar numerator: Uint256 = Uint256(diff, 0)

    %{
        print(f"time_now: {ids.time_now}")

        print(f"numerator: {ids.numerator.low}")
        print(f"denominator: {ids.denominator.low}")
    %}

    let (temp, mul_carry) = uint256_mul(numerator, MULTIPLIER_1_E_20)
    %{
        print(f"temp.low: {ids.temp.low}")
        print(f"temp.high: {ids.temp.high}")
    %}

    let (res, _) = uint256_unsigned_div_rem(temp, denominator)
    %{
        print(f"res.low: {ids.res.low}")
        print(f"res.high: {ids.res.high}")
    %}

    return ()
end