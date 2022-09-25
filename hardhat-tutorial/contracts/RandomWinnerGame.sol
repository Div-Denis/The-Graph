// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {
    //chianLink 变量
    //与请求一起发送的链接的数量
    uint256 public fee;
    //生成随机性的公钥的ID
    bytes32 public keyHash;
    
    //玩家地址
    address[] public players;
    //一场游戏最大的玩家数量
    uint8 maxPlayers;
    //表示游戏是否开始的变量
    bool public gameStarted;
    //入场费
    uint256 public entryFee;
    //当前的游戏ID
    uint256 public gameId;

    //当游戏开始时发出（游戏ID，最大游玩人数，入场费）
    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    //当有人加入游戏时发出（游戏ID， 玩家地址）
    event PlayersJoined(uint256 gameId, address player);
    //当游戏结束时发出（游戏ID， 赢家地址，请求信号ID）
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    /**
     * 构造函数继承一个VRFConsumerBase, 并初始化keyHash、Fee、和gameStarted的值
     */
    constructor(
        //VRFCoodomator合约的地址
        address vrfCoordinator,
        //LINK代币的地址
        address linkToken,
        //请求发送的LINK数量
        bytes32 vrfKeyHash,
        //生成随机性的公钥的ID
        uint256 vrfFee
        ) VRFConsumerBase (vrfCoordinator, linkToken) {
            keyHash = vrfKeyHash;
            fee = vrfFee;
            gameStarted = false;
        }

    /**
     * startGame 通过为所有变量设置合适的值来启动游戏
     */
    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        //检查游戏是否已经在运行
        require(!gameStarted, "Game  is currently running");
        //清空玩家数组
        delete players;
        //设置这个游戏的最大玩家数量
        maxPlayers = _maxPlayers;
        //设置游戏开始为true
        gameStarted = true;
        //设置游戏的入场费
        entryFee = _entryFee;
        //游戏ID加1
        gameId += 1;
        //发出开始游戏的信号
        emit GameStarted(gameId, maxPlayers, entryFee);

    }

    /**
     * 当玩家要想进入游戏时调用joinGame
     */
    function joinGame() public payable {
        //查看游戏是否已经在运行
        require(gameStarted,"Game,has not been started yet");
        //查看玩家支付的费用是否与入场费匹配
        require(msg.value == entryFee, "Value sent is not euqal to entryFee");
        //检查游戏中是否还有剩余空间可以添加其他玩家
        require(players.length < maxPlayers, "Gameis full");
        //将发件人添加到玩家列表中
        players.push(msg.sender);
        //发出玩家加入的信号
        emit PlayersJoined(gameId, msg.sender);
        //判断玩家人数是否等于最大游玩人数，人数已满则开始选择获胜者的过程
        if(players.length == maxPlayers){
            getRandomWinner();
        }
    }
    
    /**
     * 当VRF Coordinator 收到一个有效的VRF证明时，它会调用随机性
     * 该函数被覆盖，以作用于Chianlink VRF 生成的随机性
     * @param requestId 对于我们发送给VRF协调员的请求，此ID是唯一的
     * @param randomness 这是一个由VRF协调器生成并返回给我们的随机单位（uint256）
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {
        //我们希望获胜者索引的长度从0到player.length-1
        //为此，我们使用player.length的值对其进行修改
        uint256 winnerIndex = randomness & players.length;
        //从玩家数组中获取获胜者的地址
        address winner = players[winnerIndex];
        //将合约中的以太币发送给获胜者
        (bool sent,) = winner.call{value:address(this).balance}("");
        //判断是否发送
        require(sent, "Failed to senf Ether");
        //发出游戏已结束的信号
        emit GameEnded(gameId, winner, requestId);
        //将游戏开始的值设置为false
        gameStarted = false;
    }
    
    /**
     * 调用getRandomWinner 开始选择随机获胜者的过程
     */
    function getRandomWinner() public returns(bytes32 requestId){
        //LINK 是VRFConsumerBase中找到的LINK的内部接口
        //这里我们使用该接口的balanceOf方法来确保我们的合约有足够的LINK
        //所以我们可以请求VRFCoordinator的随机性
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        //向VRF协调员提出请求
        //requestRandomness是VRFConsumerBase中的一个函数
        //它开启了随机生成的过程
        return requestRandomness(keyHash,fee);
    }

    //接收以太币的功能，msg.data必须为空
    receive() external payable{}
    //当美术馆。data不为空时调用回退函数
    fallback() external payable{}

    
}
