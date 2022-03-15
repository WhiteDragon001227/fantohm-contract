// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;
pragma abicoder v2;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyPolicy() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is IERC20 {

    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library EnumerableSet {

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.
    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function _getValues(Set storage set_) private view returns (bytes32[] storage) {
        return set_._values;
    }

    // TODO needs insert function that maintains order.
    // TODO needs NatSpec documentation comment.
    /**
     * Inserts new value by moving existing value at provided index to end of array and setting provided value at provided index
     */
    function _insert(Set storage set_, uint256 index_, bytes32 valueToInsert_) private returns (bool) {
        require(set_._values.length > index_);
        require(!_contains(set_, valueToInsert_), "Remove value you wish to insert if you wish to reorder array.");
        bytes32 existingValue_ = _at(set_, index_);
        set_._values[index_] = valueToInsert_;
        return _add(set_, existingValue_);
    }

    struct Bytes4Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes4Set storage set, bytes4 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Bytes4Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes4Set storage set, uint256 index) internal view returns (bytes4) {
        return bytes4(_at(set._inner, index));
    }

    function getValues(Bytes4Set storage set_) internal view returns (bytes4[] memory) {
        bytes4[] memory bytes4Array_;
        for (uint256 iteration_ = 0; _length(set_._inner) > iteration_; iteration_++) {
            bytes4Array_[iteration_] = bytes4(_at(set_._inner, iteration_));
        }
        return bytes4Array_;
    }

    function insert(Bytes4Set storage set_, uint256 index_, bytes4 valueToInsert_) internal returns (bool) {
        return _insert(set_._inner, index_, valueToInsert_);
    }

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function getValues(Bytes32Set storage set_) internal view returns (bytes4[] memory) {
        bytes4[] memory bytes4Array_;

        for (uint256 iteration_ = 0; _length(set_._inner) >= iteration_; iteration_++) {
            bytes4Array_[iteration_] = bytes4(at(set_, iteration_));
        }

        return bytes4Array_;
    }

    function insert(Bytes32Set storage set_, uint256 index_, bytes32 valueToInsert_) internal returns (bool) {
        return _insert(set_._inner, index_, valueToInsert_);
    }

    // AddressSet
    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    /**
     * TODO Might require explicit conversion of bytes32[] to address[].
     *  Might require iteration.
     */
    function getValues(AddressSet storage set_) internal view returns (address[] memory) {

        address[] memory addressArray;

        for (uint256 iteration_ = 0; _length(set_._inner) >= iteration_; iteration_++) {
            addressArray[iteration_] = at(set_, iteration_);
        }

        return addressArray;
    }

    function insert(AddressSet storage set_, uint256 index_, address valueToInsert_) internal returns (bool) {
        return _insert(set_._inner, index_, bytes32(uint256(valueToInsert_)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    struct UInt256Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UInt256Set storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UInt256Set storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UInt256Set storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UInt256Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UInt256Set storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct =
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(- 1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & - d;
        d /= pow2;
        l /= pow2;
        l += h * ((- pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(- 1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(- 1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(- 1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface ITreasury {
    function deposit(uint _amount, address _token, uint _profit) external returns (uint send_);

    function valueOf(address _token, uint _amount) external view returns (uint value_);

    function mintRewards(address _recipient, uint _amount) external;
}

interface IStaking {
    function stake(uint _amount, address _recipient) external returns (bool);
}

interface IStakingHelper {
    function stake(uint _amount, address _recipient) external;
}

interface IMintable {
    function mint(address to, uint256 amount) external;
}

interface IBurnable {
    function burn(uint256 amount) external;
}

interface IUsdbMinter {
    function getMarketPrice() external view returns (uint);
}
interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}
interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface ITreasuryHelper {
    function bookValue() external view returns (uint);
}

/// @notice FantOHM PRO 
/// @dev based on xfhm
contract LqdrUsdbPolBondDepository is Ownable, ReentrancyGuard {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ======== EVENTS ======== */

    event BondCreated(uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD);
    event BondRedeemed(address indexed recipient, uint payout, uint remaining);




    /* ======== STATE VARIABLES ======== */
    address public immutable FHM; // token given as payment for bond
    address public immutable USDB; // USD
    address public immutable principle; // token used to create bond
    address public immutable DAO; // receives profit share from bond
    address public immutable treasury; // mints FHM when receives principle
    address public immutable usdbMinter; // receives profit share from bond
    address public immutable XFHM; // XFHM 

    uint internal constant max = type(uint).max;
    address public immutable poolRouter; // spooky/sprit to add/remove LPs
    address public lpToken; // USDB/principle LP token
    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    bool public doDiv;
    uint256 public decimals;

    address public immutable treasuryHelper; //treasury Helper address
    Terms public terms; // stores terms for new bonds

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference block for debt decay
    uint public boostFactor; // in %, 100 is 100%

    bool public useCircuitBreaker;
    mapping(address => bool) public whitelist;
    SoldBonds[] public soldBondsInHour;

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint vestingTerm; // in blocks
        uint discount; // discount in in thousandths of a % i.e. 5000 = 5%
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint soldBondsLimitUsd; //
    }

    /// @notice Info for bond holder
    struct Bond {
        uint payout; // minimal principle to be paid
        uint lpTokenAmount; // amount of lp token
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }

    struct SoldBonds {
        uint timestampFrom;
        uint timestampTo;
        uint payoutInUsd;
    }

    /* ======== INITIALIZATION ======== */

    constructor (
        address _FHM,
        address _USDB,
        address _principle,
        address _treasury,
        address _DAO,
        address _usdbMinter,
        address _poolRouter,
        address _lpToken,
        address _XFHM,
        address _treasuryHelper
    ) {
        require(_FHM != address(0));
        FHM = _FHM;
        require(_USDB != address(0));
        USDB = _USDB;
        require(_principle != address(0));
        principle = _principle;
        require(_DAO != address(0));
        DAO = _DAO;
        require(_treasury != address(0));
        treasury = _treasury;
        require(_usdbMinter != address(0));
        usdbMinter = _usdbMinter;
        require(_poolRouter != address(0));
        poolRouter = _poolRouter;
        require(_lpToken != address(0));
        lpToken = _lpToken;
        require(_XFHM != address(0));
        XFHM = _XFHM;
        require(_treasuryHelper != address(0));
        treasuryHelper = _treasuryHelper;
        boostFactor = 100;
        whitelist[msg.sender] = true;
        IERC20(_lpToken).approve(_poolRouter, max);
        IERC20(_principle).approve(_poolRouter, max);
        IERC20(_USDB).approve(_poolRouter, max);
    }

    /**
     *  @notice initializes bond parameters
     *  @param _vestingTerm uint
     *  @param _discount uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     *  @param _soldBondsLimitUsd uint
     *  @param _useCircuitBreaker bool
     */
    function initializeBondTerms(
        uint _vestingTerm,
        uint _discount,
        uint _maxPayout,
        uint _fee,
        uint _maxDebt,
        uint _initialDebt,
        uint _soldBondsLimitUsd,
        bool _useCircuitBreaker
    ) external onlyPolicy() {
        terms = Terms({
        vestingTerm : _vestingTerm,
        discount : _discount,
        maxPayout : _maxPayout,
        fee : _fee,
        maxDebt : _maxDebt,
        soldBondsLimitUsd : _soldBondsLimitUsd
        });
        totalDebt = _initialDebt;
        lastDecay = block.number;
        useCircuitBreaker = _useCircuitBreaker;
    }




    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {VESTING, PAYOUT, FEE, DEBT}
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint _input) external onlyPolicy() {
        if (_parameter == PARAMETER.VESTING) {// 0
            require(_input >= 10000, "Vesting must be longer than 10000 blocks");
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {// 1
            require(_input <= 1000, "Payout cannot be above 1 percent");
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {// 2
            require(_input <= 10000, "DAO fee cannot exceed payout");
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {// 3
            terms.maxDebt = _input;
        }
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint amount in LQDR
     *  @param _maxPrice uint should have 18 decimals
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint _amount,
        uint _maxPrice,
        address _depositor
    ) external nonReentrant returns (uint) {

        require(_depositor != address(0), "Invalid address");
        // allow only whitelisted contracts
        require(whitelist[msg.sender], "SENDER_IS_NOT_IN_WHITELIST");
        decayDebt();
        require(totalDebt <= terms.maxDebt, "Max capacity reached");

        uint lqdrPriceInUSD = bondPriceInUSD();
        require(_maxPrice >= lqdrPriceInUSD, "Slippage limit: more than max price");
        // slippage protection

        uint payoutInUsdb = payoutFor(_amount);
        // payout to bonder is computed

        require(payoutInUsdb >= 10_000_000_000_000_000, "Bond too small");
        // must be > 0.01 DAI ( underflow protection )
        require(payoutInUsdb <= maxPayout(), "Bond too large");
        // size protection because there is no slippage
        require(!circuitBreakerActivated(payoutInUsdb), "CIRCUIT_BREAKER_ACTIVE");
        uint payoutInFhm = payoutInFhmFor(payoutInUsdb);

        // profits are calculated
        uint fee = payoutInFhm.mul(terms.fee).div(10000);

        IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);

        ITreasury(treasury).mintRewards(address(this), payoutInFhm.add(fee));

        // mint USDB with guaranteed discount
        IMintable(USDB).mint(address(this), payoutInUsdb);

        // burn whatever FHM got from treasury in current market price
        IBurnable(FHM).burn(payoutInFhm);

        // burn xFHM deposits
        IBurnable(XFHM).burn(feeInXfhm(_amount));

        uint _lpTokenAmount = createLP(_amount, payoutInUsdb);

        if (fee != 0) {// fee is transferred to dao
            IERC20(FHM).safeTransfer(DAO, fee);
        }

        // total debt is increased
        totalDebt = totalDebt.add(_amount);

        // update sold bonds
        if (useCircuitBreaker) updateSoldBonds(payoutInUsdb);

        uint bondPayout = bondInfo[_depositor].payout;
        // depositor info is stored
        bondInfo[_depositor] = Bond({
        payout : bondPayout.add(_amount), // FIXME here we need to count payout in LQDR not USDB!!!
        lpTokenAmount : bondInfo[_depositor].lpTokenAmount.add(_lpTokenAmount),
        vesting : terms.vestingTerm,
        lastBlock : block.number,
        pricePaid : lqdrPriceInUSD
        });
        // indexed events are emitted
        emit BondCreated(_amount, payoutInUsdb, block.number.add(terms.vestingTerm), lqdrPriceInUSD);

        return payoutInUsdb;
    }

    function createLP(uint _principleAmount, uint _usdbAmount) private returns (uint _lpTokenAmount) {
        (,, _lpTokenAmount) =
        IUniswapV2Router02(poolRouter).addLiquidity(
            USDB,
            principle,
            _usdbAmount,
            _principleAmount,
            1,
            1,
            address(this),
            deadline
        );
    }

    function removeLP(uint _lpTokensAmount) private returns (uint _usdbAmount, uint _principleAmount) {
        (_usdbAmount, _principleAmount) = IUniswapV2Router02(poolRouter).removeLiquidity(
            USDB,
            principle,
            _lpTokensAmount,
            1,
            1,
            address(this),
            deadline
        );

    }
    /**
    *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _amount uint amount of lptoken
     *  @param _amountMin uint
     *  @param _stake bool
     *  @return uint
     */
    // FIXME we need to add slippage to remove and add liquidity, otherwise it will cause huge price impact
    function redeem(address _recipient, uint _amount, uint _amountMin, bool _stake) external nonReentrant returns (uint) {
        Bond memory info = bondInfo[_recipient];
        require(_amount >= info.lpTokenAmount, "Exceed the deposit amount");
        uint percentVested = percentVestedFor(_recipient);
        // (blocks since last interaction / vesting term remaining)

        require(whitelist[msg.sender], "SENDER_IS_NOT_IN_WHITELIST");
        require(percentVested >= 10000, "Wait for end of bond");

        // disassemble LP into tokens
        (uint _usdbAmount, uint _principleAmount) = removeLP(_amount);
        require(_principleAmount >= _amountMin, "Slippage limit: more than amountMin");
        // no IL protection here

        IBurnable(USDB).burn(_usdbAmount);
        IERC20(principle).transfer(_recipient, _principleAmount);

        info.payout = info.payout.sub(_principleAmount);
        info.lpTokenAmount = info.lpTokenAmount.sub(_amount);
        
        // delete user info
        if(info.lpTokenAmount == 0) {
            delete bondInfo[_recipient];
        }

        emit BondRedeemed(_recipient, _principleAmount, 0);
        // emit bond data

        return _principleAmount;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    function modifyWhitelist(address user, bool add) external onlyPolicy {
        if (add) {
            require(!whitelist[user], "ALREADY_IN_WHITELIST");
            whitelist[user] = true;
        } else {
            require(whitelist[user], "NOT_IN_WHITELIST");
            delete whitelist[user];
        }
    }

    // FIXME asking if we need this function in here, if not we will remove it
    function updateSoldBonds(uint _payout) internal {
        uint length = soldBondsInHour.length;
        if (length == 0) {
            soldBondsInHour.push(SoldBonds({
            timestampFrom : block.timestamp,
            timestampTo : block.timestamp + 1 hours,
            payoutInUsd : _payout
            }));
            return;
        }

        SoldBonds storage soldBonds = soldBondsInHour[length - 1];
        // update in existing interval
        if (soldBonds.timestampFrom < block.timestamp && soldBonds.timestampTo >= block.timestamp) {
            soldBonds.payoutInUsd = soldBonds.payoutInUsd.add(_payout);
        } else {
            // create next interval if its continuous
            uint nextTo = soldBonds.timestampTo + 1 hours;
            if (block.timestamp <= nextTo) {
                soldBondsInHour.push(SoldBonds({
                timestampFrom : soldBonds.timestampTo,
                timestampTo : nextTo,
                payoutInUsd : _payout
                }));
            } else {
                soldBondsInHour.push(SoldBonds({
                timestampFrom : block.timestamp,
                timestampTo : block.timestamp + 1 hours,
                payoutInUsd : _payout
                }));
            }
        }
    }

    // FIXME asking if we need this function in here, if not we will remove it
    function circuitBreakerCurrentPayout() public view returns (uint _amount) {
        if (soldBondsInHour.length == 0) return 0;

        uint max = 0;
        if (soldBondsInHour.length >= 24) max = soldBondsInHour.length - 24;

        uint to = block.timestamp;
        uint from = to - 24 hours;
        for (uint i = max; i < soldBondsInHour.length; i++) {
            SoldBonds memory soldBonds = soldBondsInHour[i];
            if (soldBonds.timestampFrom >= from && soldBonds.timestampFrom <= to) {
                _amount = _amount.add(soldBonds.payoutInUsd);
            }
        }

        return _amount;
    }

    function circuitBreakerActivated(uint payout) public view returns (bool) {
        if (!useCircuitBreaker) return false;
        payout = payout.add(circuitBreakerCurrentPayout());
        return payout > terms.soldBondsLimitUsd;
    }

    /// @notice LQDR market price
    function getMarketPrice() public view returns (uint256) {
        // FIXME (optional) can we move it away, if we for example have price oracle from DAI?
        // just to set different address, that's why there is usdb minter in here
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(lpToken).getReserves();
        if (IUniswapV2Pair(lpToken).token0() == principle) {
            if (doDiv) return reserve1.div(reserve0).div(10 ** decimals);
            else return reserve1.mul(10 ** decimals).div(reserve0);
        } else {
            if (doDiv) return reserve0.div(reserve1).div(10 ** decimals);
            else return reserve0.mul(10 ** decimals).div(reserve1);
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.number;
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        return IERC20(USDB).totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint _value) public view returns (uint) {
        // FIXME this is payout in USDB for given _value in LQDR, because we are using it inside deposit function
        // we need this to count how many USDB => FHM to mint
        return FixedPoint.fraction(_value, getMarketPrice()).decode112with18();
    }

    function payoutInFhmFor(uint _usdbValue) public view returns (uint) {
        // FIXME this is payout in FHM for given _usdbValue or stablecoin value, so here "market price" needs to be price of FHM
        return FixedPoint.fraction(_usdbValue, IUsdbMinter(usdbMinter).getMarketPrice()).decode112with18().div(1e16).div(1e9);
    }

    /// @notice return book value per 1 FHM in 18 decimals
    function bookValueInFhm() public view returns (uint) {
        return ITreasuryHelper(treasuryHelper).bookValue();
    }

    /// @dev lqdr_amount = 3.3 * xfhm_amount * boostFactor * bookValue_fhm => amount_xfhm = lqdr_amount / 3.3 / boostFactor / bookValue_fhm
    function feeInXfhm(uint _lqdrAmount) public view returns (uint) {
        return _lqdrAmount
        .mul(10).div(33)
        .mul(boostFactor).div(100)
        .div(bookValueInFhm());
    }


    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns (uint price_) {
        // FIXME this should have 18 decimals, why you div(100) here?
        price_ = getMarketPrice();
    }

    /**
     *  @notice calculate current ratio of debt to USDB supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint debtRatio_) {
        uint supply = IERC20(USDB).totalSupply();
        debtRatio_ = FixedPoint.fraction(
            currentDebt().mul(1e9),
            supply
        ).decode112with18().div(1e18);
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns (uint) {
        return debtRatio();
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint decay_) {
        uint blocksSinceLast = block.number.sub(lastDecay);
        decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }


    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor) public view returns (uint percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint blocksSinceLast = block.number.sub(bond.lastBlock);
        uint vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = blocksSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of LQDR available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint pendingPayout_) {
        uint percentVested = percentVestedFor(_depositor);
        // FIXME here you should look how many tokens exactly you would get from LP position
        uint actualPayout = balanceOfPooled(_depositor);    

         // return original amount + trading fees (half of LP token amount) or deposited amount in case of IL (will pay difference in FHM)
        uint payout = Math.max(actualPayout, bondInfo[_depositor].payout);

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = 0;
        }
    }

    function setBoostFactor(uint _boostFactor) external onlyPolicy {
        boostFactor = _boostFactor;
    }

    function setLqdrLpAddress(address _lpToken, uint256 _decimals, bool _doDiv) external virtual onlyPolicy {
        lpToken = _lpToken;
        decimals = _decimals;
        doDiv = _doDiv;
    }

    /// @notice computes actual allocation inside LP token from your position
    /// @param _depositor user
    /// @return payout_ in principle
    function balanceOfPooled(address _depositor) public view returns (uint payout_) {
        uint lpTokenAmount = bondInfo[_depositor].lpTokenAmount;

        ( uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        if(IUniswapV2Pair(lpToken).token0() == principle) {
            return reserve0.mul(lpTokenAmount).div(IERC20(lpToken).totalSupply());
        } else {
            return reserve1.mul(lpTokenAmount).div(IERC20(lpToken).totalSupply());
        }

        return 0;
    }

    /* ======= AUXILLIARY ======= */
    /**
     *  @notice allow anyone to send lost tokens (excluding principle or FHM) to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token) external returns (bool) {
        require(_token != FHM);
        require(_token != USDB);
        require(_token != principle);
        IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
        return true;
    }
}
