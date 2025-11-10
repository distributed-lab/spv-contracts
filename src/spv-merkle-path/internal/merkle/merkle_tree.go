package merkle

import "crypto/sha256"

type MerkleTree struct {
	leafTag string
	nodeTag string
	leaves  [][32]byte
	levels  [][][32]byte
}

func NewMerkleTree(leafTag string, nodeTag string) MerkleTree {
	return MerkleTree{
		leafTag: leafTag,
		nodeTag: nodeTag,
		leaves:  make([][32]byte, 0),
		levels:  make([][][32]byte, 0),
	}
}

func (mt *MerkleTree) HashLeaf(data []byte) [32]byte {
	return sha256.Sum256(append([]byte(mt.leafTag), data...))
}

func (mt *MerkleTree) HashNode(left [32]byte, right [32]byte) [32]byte {
	return sha256.Sum256(append(append([]byte(mt.nodeTag), left[:]...), right[:]...))
}

func (mt *MerkleTree) AddLeaf(data []byte) {
	mt.leaves = append(mt.leaves, mt.HashLeaf(data))
}

func (mt *MerkleTree) BuildTree() {
	nodes := mt.leaves
	mt.levels = append(mt.levels, nodes)
	for len(nodes) > 1 {
		nextLevel := make([][32]byte, 0)
		for i := 0; i < len(nodes); i += 2 {
			left := nodes[i]
			right := nodes[i+1]
			nextLevel = append(nextLevel, mt.HashNode(left, right))
		}
		nodes = nextLevel
		mt.levels = append(mt.levels, nodes)
	}
}

func (mt *MerkleTree) Root() [32]byte {
	if len(mt.levels) == 0 {
		mt.BuildTree()
	}
	return mt.levels[len(mt.levels)-1][0]
}

func (mt *MerkleTree) MerklePath(index uint64) [][32]byte {
	path := make([][32]byte, 0)

	for _, elem := range mt.levels[:(len(mt.levels) - 1)] {
		siblingIndex := index ^ 1
		if int(siblingIndex) < len(elem) {
			path = append(path, elem[siblingIndex])
		}
		index /= 2
	}

	return path
}
