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
                ```
                * write:
                ```solidity
                function commit(bytes32 commitment) public;

                function register(string name, address owner, uint duration, bytes32 secret) public payable;
                => event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
                ```
            * external:
                * write:
                ```solidity
                function renew(string name, uint duration) external payable;
                event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
                ```
### Gravity Bridge
* `Gravity`
    * 功能：该合约是`EVM`类公链（如ethereum，bsc，tron等）向`WNS`公链跨链传递信息和资产的关键合约。
    * 特性：
        * 不依赖中间第三方，仅需依赖`WNS`公链的验证人合集。
    * 接口：
        ```solidity
        function updateValset()
        function submitBatch()
        function sendToCosmos()
        ```
    * 参考：
        * https://github.com/Gravity-Bridge/Gravity-Bridge/blob/main/solidity/contracts/contract-explanation.md

### ERC4337 账户抽象
* `Wallet`
    * 功能：该合约是实现了合约钱包功能，支持任意的验证方式以及执行任意逻辑等
    * 特性：
        * 支持多签和社交恢复
        * 支持其他种类的密码学签名验证算法
        * 可升级
    * 参考：
        * https://github.com/ethereum/EIPs/blob/3fd65b1a782912bfc18cb975c62c55f733c7c96e/EIPS/eip-4337.md
                

## 未实现合约

* `ReservedDomains`
    * 功能：该合约保留一部分精品web3域名，并设立保留期限，在到期前不支持用户注册该域名，到期后这部分域名将公开拍卖，拍卖所得收入将进入金库给用户和`DAO`分红。
    * 特性：
        * 存储需保留的`web3`域名，并允许该合约的`controller`添加或移除保留域名。
        * `Registry`或`Web3Registrar`等其他合约可查询某`web3`域名是否在保留库中。
        * 提供域名锁定`timelock`功能。
        * 当`timelock`满足条件之后，支持`delegatecall`某个`Auction`竞拍合约对保留域名进行拍卖。
        * 该合约的`controller`可更换`Auction`合约，以方便升级竞拍逻辑。
        * 在非`WNS`公链的其他公链部署时不支持竞拍功能。
    * 接口：
        * external:
            * read:
            ```solidity
            * function isReserved(string name) view external returns(bool);
            ```
            * write:
            ```solidity
            * function addReservedName(string name) onlyController external;
            => event NameAdded(string name)
            
            * function removeReservedName(string name) onlyController external;
            => event NameRemoved(string name)
            ```

                

                