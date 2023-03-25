// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IMaintainer} from "./interfaces/IMaintainer.sol";

contract CANAANS is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    IMaintainer public Maintainer;
    // MINT_TYPEHASH = keccak256("Unlock(address to,bytes32 seed)");
    bytes32 public MINT_TYPEHASH;
    mapping(uint256 => uint256) public Faith;
    mapping(uint256 => uint256) public Mana;
    mapping(uint256 => uint256) public Power;
    // random
    uint randomCounter;
    mapping(bytes32 => bool) public seedStatus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://amber-openverse.s3.ap-northeast-1.amazonaws.com/AVATAR/metadata/";
    }

    function initialize(IMaintainer _IMaintainer) public initializer {
        __ERC721_init("CANAANS", "Rabbi");

        Maintainer = _IMaintainer;
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        StringsUpgradeable.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    //////

    function mintRabbi(
        address to,
        bytes32 seed,
        bytes calldata signatures
    ) external nonReentrant whenNotPaused {
        // 1. calc msgHash
        bytes32 msgHash = getMintMsgHash(to, seed);
        Maintainer.validatorsApprove(msgHash, signatures);
        require(!seedStatus[seed], "Error: Seed has been used.");
        setSeedStatus(seed, true);

        uint256 randomFaith = ((random(seed)) % 50) + 60;
        uint256 randomMana = ((random(seed)) % 50) + 60;
        uint256 randomPower = ((random(seed)) % 50) + 60;

        uint256 tokenId = _tokenIdCounter.current();

        Faith[tokenId] = randomFaith;
        Mana[tokenId] = randomMana;
        Power[tokenId] = randomPower;

        safeMint(to);
    }

    function burnRabbi(uint tokenId) public onlyOwner {
        delete Faith[tokenId];
        delete Mana[tokenId];
        delete Power[tokenId];
        _burn(tokenId);
    }

    function modifyAttributes(
        uint tokenId,
        uint[] memory attributes
    ) public onlyOwner {
        require(attributes.length == 3);
        Faith[tokenId] = attributes[0];
        Mana[tokenId] = attributes[1];
        Power[tokenId] = attributes[2];
    }

    function getMintMsgHash(
        address to,
        bytes32 seed
    ) public view returns (bytes32 msgHash) {
        msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01", // solium-disable-line
                Maintainer.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(MINT_TYPEHASH, to, seed))
            )
        );
    }

    function setSeedStatus(bytes32 seed, bool status) internal {
        seedStatus[seed] = status;
    }

    function random(bytes32 seed) internal returns (uint) {
        // sha3 and now have been deprecated
        randomCounter++;
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.timestamp,
                        seed,
                        randomCounter
                    )
                )
            );
        // convert hash to integer
        // players is an array of entrants
    }
}
