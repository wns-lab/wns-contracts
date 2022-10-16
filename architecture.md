# WNS 合约接口设计与实现

## 已有合约

### ENS contracts

* `Registry`:
    * 功能：
        * 维护域名，域名的拥有者（**owner**），域名解析合约以及`TTL`等记录，域名的拥有者可以修改这些记录，同时该合约也是所有查询功能的入口，负责对域名**owner**鉴权。
    * 特性：
        * 一个域名只有一个**owner**账户，该账户可能是**EOA**或者合约账户
        * 域名解析合约（**resolver**）负责该域名的解析工作
        * ==在非WNS公链上部署时本合约仅支持该公链的原生地址成为域名的**owner**，在WNS公链上部署时本合约支持所有WNS协议已兼容的公链的原生地址均可成为域名的**owner**（未实现）==
        * ==当用户新注册或者更新域名及域名的**owner**等信息时，如果本合约所在公链存在实现了IBC协议的跨链合约（预编译合约或普通智能合约），本合约需要调用跨链合约将信息同步到WNS公链或**owner**原生的公链，如果跨链失败，本合约需回滚所有状态（未实现）==
    * 接口:
        * public:
            * read:
            ```solidity
                * function recordExists(bytes32 node) public view returns (bool);
            ```
            * write:
            ```solidity
                * function setRecord(bytes32 node, address owner, address resolver, uint64 ttl);
                * function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl);
                * function setApprovalForAll(address operator, bool approved);
            ```
        * external:
            * read:
            ```solidity
                * function owner(bytes32 node) external view returns (address);
                * function resolver(bytes32 node) external view returns (address);
                * function ttl(bytes32 node) external view returns (uint64);
                * function isApprovedForAll(address owner, address operator) external view returns (bool);
            ```
            * write:
            ```solidity
                * function setOwner(bytes32 node, address owner) external; 
                => event Transfer(bytes32 indexed node, address owner);
                * function setResolver(bytes32 node, address resolver) external; 
                => event NewResolver(bytes32 indexed node, address resolver);
                * function setTTL(bytes32 node, uint64 ttl) external; 
                => event NewTTL(bytes32 indexed node, uint64 ttl);
                * function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external; 
                => event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
            ```
        * ==internal（未实现）==:
            * write：
            ```solidity
                * function sendToWNS(bytes32 indexed node, address owner, input bytes) internal;
                * function sendToNative(bytes32 indexed node, address owner, input bytes) internal;
            ```
* WNS Registrar:
    * `Web3Registrar`
        * 功能：
            * 该合约是`.web3`顶级域的**owner**，并且根据规则向用户分配`web3`域名。
        * 特性：
            * 该合约的**owner**可以添加或移除该合约的**controllers**。
            * 该合约的**controllers**可以注册新的`web3`域名，并且延长已有`web3`域名的过期时间，但是不能改变已有`web3`域名的所有权或者降低已有子域名的过期时间。
            * `web3`域名的**owner**可以将域名的所有权转移给其他账户。
            * 该合约中`web3`域名的**owner**可以在`Registry`合约中重新获取对相应`web3`域名的所有权。
            * `Registry`合约管理`web3`域名的所有权，而本合约管理`web3`域名的注册权，并且后者的权益优先于前者，也就是说注册权的**owner**可以将`web3`域名的所有权转移给其他账户如智能合约，并仍然保留注册权，并且在需要时在`Registry`合约中重置对该域名的所有权。
        * 接口：
            * public:
                * read:
                ```solidity
                function available(uint256 label) public view returns(bool);
                uint public transferPeriodEnds;
                mapping(address=>bool) public controllers;
                function getApproved(uint256 tokenId) public view returns (address operator);
                function getApproved(uint256 tokenId) public view returns (address operator);
                ```
                * write:
                ```solidity
                function transferFrom(address from, address to, uint256 tokenId) public;
                function safeTransferFrom(address from, address to, uint256 tokenId) public;
                function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
                => event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
                
                function approve(address to, uint256 tokenId) public;
                function setApprovalForAll(address operator, bool _approved) public;
                ```
            * external:
                * read:
                ```solidity
                function nameExpires(uint256 label) external view returns(uint);
                function ownerOf(uint256 label) external view returns(address);
                ```
                * write:
                ```solidity
                function reclaim(uint256 label) external;
                ```
    * `Web3RegistrarController`
        * 功能：
            * 除了作为`Web3Registrar`合约的**controller**之外，该合约还有防止用户注册域名被抢跑的功能。
        * 特性：
            * 用户结合域名和一个自己生成的任意的`secret`生成`commitment hash`.
            * 用户将`commitment hash`提交给该合约。
            * 用户需要在至少一分钟，最多24小时后提交域名注册申请，并且一并提交`secret`供该合约验证。
            * ==该合约需将用户的注册费用归集到`Treasury`合约中（未实现）==
        * 接口：
            * public:
                * read:
                ```solidity
                uint constant public MIN_COMMITMENT_AGE;
                uint constant public MAX_COMMITMENT_AGE;
                uint constant public MIN_REGISTRATION_DURATION;
                mapping(bytes32=>uint) public commitments;
                
                function rentPrice(string name, uint duration) view public returns(uint);
                function valid(string name) public view returns(bool);
                function available(string name) public view returns(bool);
                function makeCommitment(string name, address owner, bytes32 secret) pure public returns(bytes32);
                function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32)
                ```
                * write:
                ```solidity
                function commit(bytes32 commitment) public;

                function register(string name, address owner, uint duration, bytes32 secret) public payable;
                => event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
                
                function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable;
                => event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
                
                function renew(string calldata name, uint duration) external payable
                => event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
                ```
            * external:
                * write:
                ```solidity
                function renew(string name, uint duration) external payable;
                event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
                ```

    * `PublicResolver`
        * 功能：
            * 该合约实现了适用于大多数标准 ENS 用例的通用 ENS 解析器。公共解析器允许相应名称的所有者更新 ENS 记录。
        
        * 接口：
        
            * wirte
        ```solidity
        function setApprovalForAll(address operator, bool approved) external

        function multicall(bytes[] calldata data) external returns(bytes[] memory results)

        function setAddr(bytes32 node, uint coinType, bytes memory a) public authorised(node)
        ```
        
        * read:
        ```solidity
        function isAuthorised(bytes32 node) internal override view returns(bool)

        function isApprovedForAll(address account, address operator) public view returns (bool)

        function addr(bytes32 node) public view returns (address payable)

        function addr(bytes32 node, uint coinType) public view returns(bytes memory)

        function name(bytes32 node) external view returns (string memory)
        ```
        
    * `PriceOracle`
        * 接口
            * external
            ```solidity
            function price(string calldata name, uint expires, uint duration) external view returns(uint)
            ```
