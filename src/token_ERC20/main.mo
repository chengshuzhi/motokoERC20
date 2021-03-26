import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

actor Token_ERC20 {
    
    //isInit_ 变量用来描述该代币是否已经被发行
    private stable var isInit_ : Bool = false;

    private stable var name_ : Text = "";
    private stable var decimals_ : Nat = 0;
    private stable var symbol_ : Text = "";
    private stable var totalSupply_ : Nat = 0;

    // TODO  
    private var balances = HashMap.HashMap<Principal,Nat>(1,Principal.equal,Principal.hash);
    private var allowed = HashMap.HashMap<Principal,HashMap.HashMap<Principal,Nat>>(1,Principal.equal,Principal.hash);

    //发行代币init
    public shared(msg) func init(_name: Text, _symbol: Text, _decimals: Nat, _totalSupply: Nat) : async Bool {
        assert(isInit_ == false);

        name_ := _name;
        symbol_ := _symbol;
        decimals_ := _decimals;
        totalSupply_ := _totalSupply * 10 ** _decimals;
        balances.put(msg.caller,totalSupply_);
        isInit_ := true;
        return true;

    };

    //分发代币transfer， 发行代币者才能调用
    public shared(msg) func transfer(to: Principal, value: Nat) : async Bool {
        assert(isInit_);
        switch(balances.get(msg.caller)) {
            case (?caller_balance) { // TODO  
                if (caller_balance >= value) {
                    var caller_balance_new = caller_balance - value;
                    var to_balance_new = switch (balances.get(to)) {
                        case (? to_balance) { // TODO 
                            to_balance + value;
                        };
                        case(_){
                            value;
                        };
                    };
                    assert(to_balance_new >= value);
                    balances.put(msg.caller, caller_balance_new);
                    balances.put(to, to_balance_new);
                    return true;
                } else {
                    return false;
                };
            };
            case(_) {
                return false;
            };
        }

    };

    //转移代币transferFrom
    public shared(msg) func transferFrom(from: Principal, to: Principal, value: Nat) : async Bool {
        assert(isInit_);
        switch(balances.get(from), allowed.get(from)) {
            case(?from_balance, ?allow_to) {
                switch (allow_to.get(msg.caller)) { 
                    case (?allow_num) {
                        if (from_balance >= value and allow_num >= value) {
                            var from_balance_new = from_balance - value;
                            var allow_num_new = allow_num - value;
                            var to_balance_new = switch (balances.get(to)) {
                                case (?to_balance) {
                                    to_balance + value;
                                };
                                case(_) {
                                    value;
                                };
                            };
                            assert(to_balance_new >= value);
                            allow_to.put(msg.caller,allow_num_new);
                            allowed.put(from,allow_to);
                            balances.put(from, from_balance_new);
                            balances.put(to,to_balance_new);
                            return true;
                        } else {
                            return false;
                        };
                    };
                    case (_) {
                        return false;
                    };
                }
            };
            case (_) {
                return false;
            };
        }

    };


    //设定当前账户对指定账户的允许转账量
    public shared(msg) func approve(spender: Principal, value: Nat) : async Bool {

        assert(isInit_);

        switch (allowed.get(msg.caller)) {
            case (?allow_to) {
                allow_to.put(spender,value);
                allowed.put(msg.caller,allow_to);
                return true;
            };
            case (_) {
                var temp = HashMap.HashMap<Principal,Nat>(1,Principal.equal,Principal.hash);
                temp.put(spender,value);
                allowed.put(msg.caller,temp);
                return true;
            };
        }
    };

    //返回指定地址还能从owner地址提取的代币余额
    public query func allowance(owner: Principal, spender:Principal) : async Nat {

        switch (allowed.get(owner)) {
            case (?allow_to) {
                switch(allow_to.get(spender)) {
                    case (? allow_num) {
                        return allow_num;
                    };
                    case (_) {
                        return 0 ;
                    };
                }
            };
            case (_) {
                return 0;
            };
        }

    };

    // 余额查询
    public query func balanceOf(who: Principal) : async Nat {

        switch (balances.get(who)) {
            case (?balance) {
                return balance;
            };
            case (_) {
                return 0 ;
            };
        }

    };


    public query func totalSupply() : async Nat {
        return totalSupply_;
    };

    public query func name() : async Text {
        return name_;
    };

    public query func symbol() : async Text {
        return symbol_;
    };

    public query func decimals() : async Nat {
        return decimals_;
    };

    public shared(msg) func callerPrincipal() : async Principal {
        return msg.caller;
    };
};
