#!/usr/bin/env python3
#
# Aliaume Lopez
#
# This script generates figures representing some relation
# between words using Hasse diagrams.
# 

import itertools as it
from functools import cmp_to_key

def repr_word(l):
    return "".join(l)



def repr_tikz(l):
    if l == "":
        return "epsilon"
    else:
        return l


def repr_math(l):
    if l == "":
        return "$\\varepsilon$" 
    else:
        return l    



def subword(u,v):
    if u == "":
        return True

    if len(u) > len(v):
        return False

    if u[0] == v[0]:
        return subword(u[1:], v[1:]) or subword(u, v[1:])
    else:
        return subword(u, v[1:])


def prefix(u,v):
    return v.startswith(u)

def suffix(u,v):
    return v.endswith(u)

def infix(u,v):
    for i in range(len(v)-len(u)+1):
        if v[i:i+len(u)] == u:
            return True
    return False

def print_power(u,n):
    if n <= 1:
        return u*n
    else:
        return f"{{{u}^{n}}}"

def compress_word(u):
    # group u by letters
    # and replace each block
    # by the print_power(x,n)
    if u == "":
        return ""
    else:
        l = it.groupby(u, lambda x: x)
        return "".join( print_power(u, len(list(v))) for (u,v) in l if len(u) == 1)


def encode_item_in_infix(item):
    layer_num, item_num, dwset = item["layer_num"], item["item_num"], item["dwset"]
    # f(0, i, _) = a b^i a
    # f(n+1, i, D) = c^{n+1} b^i c^{n+1} \prod_{d \in D} (f(n, i, d) c^{n+1})
    if layer_num == 0:
        return "a" + "b"* item_num + "a"
    else:
        sep = "c"* layer_num
        dwset_enc = sep.join(encode_item_in_infix(dw) for dw in dwset)
        return "".join([sep, "b"*item_num, sep, dwset_enc, sep])


def encode_in_infix(nodes, edges):
    # we compute layers
    # based on the minimal elements
    # minimal elements
    layer_num = 0
    item_num = 1

    for n in nodes.values():
        if not any(e["to"] == n["word"] for e in edges):
            n["layer_num"] = layer_num
            n["item_num"] = item_num
            item_num += 1

    layer_num = 1
    while any(n.get("layer_num",None) is None for n in nodes.values()):
        item_num = 1
        for n in nodes.values():
            # exists m. m -> n with m.layer_num = layer_num - 1
            # then n.layer_num = layer_num
            if any(e["to"] == n["word"] and nodes[e["from"]].get("layer_num", None) == layer_num - 1 for e in edges):
                n["layer_num"] = layer_num
                n["item_num"] = item_num
                item_num += 1
        layer_num += 1

    for n in nodes.values():
        n["dwset"] = [nodes[e["from"]] for e in edges if e["to"] == n["word"]]

    for n in nodes.values():
        n["infix_enc"] = encode_item_in_infix(n)
        n["x"] = (n["x"] - 0.5) * 5

    return (nodes, edges)

    





def generate_figure(size = 4, relation = subword):
    # We create a "triangle-like" 
    # figure with the empty word ε at the bottom
    # and each layer containing all the words of size k
    # on top of eachother, and centered based on their size

    layers = []
    for k in range(size):
        words = list(it.product("ab", repeat=k))
        layers.append(words)
    layers[0] = [""]

    # The "nodes", are then dicts 
    # with { "word": "abab", "x": x, "y": y}      
    nodes = {}
    for i in range(size):
        layer_size = 2**i # =  len(layers[i])
        for j, word in enumerate(layers[i]):
            x = j - layer_size/2
            y = i
            w = repr_word(word)
            nodes[w] = {"word": w,
                           "x": x, 
                           "y": y}

    # Now we create the edges of the Hasse Diagram 
    # based on the relation
    edges = []
    for i in range(size-1):
        for ui in layers[i]:
            for vi in layers[i+1]:
                u = repr_word(ui)
                v = repr_word(vi)
                if relation(u,v):
                    edges.append({ "from": u, "to": v })

    return (nodes, edges)

def antichain_branch_ab(size = 4):
    nodes, edges = generate_figure(size, prefix)
    for n in nodes.values():
        w = n["word"]
        if w.count("a") == len(w):
            n["branch"] = True
        if len(w) > 0 and w.count("a") == len(w) - 1 and w[-1] == "b":
            n["antichain"] = True

    for e in edges:
        u = e["from"]
        v = e["to"]
        if nodes[u].get("branch", False) and nodes[v].get("branch", False):
            e["branchEdge"] = True
        elif nodes[u].get("branch", False) and nodes[v].get("antichain", False):
            e["outEdge"] = True

    return (nodes, edges)


def render_figure_matplotlib(nodes, edges):
    # We render the figure using matplotlib
    import matplotlib.pyplot as plt

    for e in edges:
        u = e["from"]
        v = e["to"]
        plt.plot([nodes[u]["x"], nodes[v]["x"]], [-nodes[u]["y"], -nodes[v]["y"]], 'k-')

    for node in nodes.values():
        plt.text(node["x"], -node["y"], node["word"], fontsize=12, ha='center', va='center')

    plt.gca().invert_yaxis()
    plt.axis('off')
    plt.show()


def render_figure_tikz(nodes, edges, compare_with=None, standalone=True, infix_enc=False):
    # We render the figure using TikZ
    if standalone:
        print(r"""%  This document is generated by `src/word-embeddings-figure.py`
%  Please do not edit it directly as it will be likely overwritten
%  The figure represents a Hasse diagram of a relation between words
%  The words are represented as nodes and the relation as edges
%  The figure is generated using TikZ and can be included in a LaTeX document
%  using the `standalone` class/package.
\documentclass[tikz]{standalone}
\usepackage{tikz}
\usepackage{ensps-colorscheme}
\begin{document}
\begin{tikzpicture}[
        isWord/.style={rectangle,inner sep=0mm},
        isEmbedding/.style={->, >=stealth, thick},
        branch/.style={A5},
        antichain/.style={A2},
        branchEdge/.style={A5,dashed},
        outEdge/.style={dotted,B2},
        isInfixEnc/.style={},
        isRealWord/.style={A4,opacity=0.2},
        isRealEmbedding/.style={A4,opacity=0.2},
        isNewEdge/.style={B2},
        ]

        """)

    has_infix_enc = any(node.get("infix_enc") for node in nodes.values())
    if has_infix_enc:
        for node in nodes.values():
            node["isWord"] = True
            node["isInfixEnc"] = True
            params = ",".join(f"{k}" for (k,v) in node.items() if type(v) == bool and  v == True )
            print(f"\\node[{params}] (I{repr_tikz(node['word'])}) at ({node['x'] + 0.3}, {node['y'] + 0.3}) {{\\strut ${repr_math(compress_word(node['infix_enc']))}$}};")

        for e in edges:
            u = e["from"]
            v = e["to"]
            e["isEmbedding"] = True
            params = ",".join(f"{k}" for (k,v) in e.items() if type(v) == bool and v == True )
            print(f"\\draw[{params}] (I{repr_tikz(u)}) -- (I{repr_tikz(v)});")


    for node in nodes.values():
        node["isWord"] = True
        node["isRealWord"] = has_infix_enc
        params = ",".join(f"{k}" for (k,v) in node.items() if type(v) == bool and  v == True )
        print(f"\\node[{params}] ({repr_tikz(node['word'])}) at ({node['x']}, {node['y']}) {{\\strut {repr_math(node['word'])}}};")

    for e in edges:
        u = e["from"]
        v = e["to"]
        e["isEmbedding"] = True
        e["isRealEmbedding"] = has_infix_enc
        e["isNewEdge"] = compare_with and (not has_infix_enc) and (not compare_with(u,v))
        params = ",".join(f"{k}" for (k,v) in e.items() if type(v) == bool and v == True )
        print(f"\\draw[{params}] ({repr_tikz(u)}) -- ({repr_tikz(v)});")


    if standalone:
        print(r"""
\end{tikzpicture}
\end{document}
        """)

if __name__ == "__main__":
    # By default we render the figure using TikZ and printing in the 
    # standard output. We take as arguments
    # --relation = subword|prefix|infix|suffix
    # --size = 4
    # --output = tikz|matplotlib
    import argparse
    parser = argparse.ArgumentParser(description='Generate Hasse Diagrams for words')
    parser.add_argument('--relation', type=str, default="subword", help='The relation to use (subword, prefix, infix, suffix)')
    parser.add_argument('--size', type=int, default=4, help='The maximal size of the words')
    parser.add_argument('--output', type=str, default="tikz", help='The output format (standalone, tikz, matplotlib)')
    parser.add_argument("--antichain", type=bool, default=False, help="Generate an antichain figure")
    parser.add_argument("--infix-enc", type=bool, default=False, help="Encode the infix in the nodes")
    parser.add_argument("--compare-with", type=str, default="None", help="Compare with another relation (None, prefix, infix, suffix, subword)")

    args = parser.parse_args()
    if args.antichain:
        nodes, edges = antichain_branch_ab(args.size)
    elif args.infix_enc:
        nodes, edges = generate_figure(args.size, eval(args.relation))
        nodes, edges = encode_in_infix(nodes, edges)
    else:
        nodes, edges = generate_figure(args.size, eval(args.relation))

    if args.output == "matplotlib":
        render_figure_matplotlib(nodes, edges)
    elif args.output == "tikz":
        render_figure_tikz(nodes, edges, standalone=False, compare_with=eval(args.compare_with))
    elif args.output == "standalone":
        render_figure_tikz(nodes, edges, standalone=True, compare_with=eval(args.compare_with))
    else:
        print("Unknown output format")

    


# -- Unit Tests --
def test_subword_empty():
    assert subword("", "")
    assert subword("", "a")
    assert subword("", "aba")
    assert (not subword("a", ""))
    assert (not subword("aba", ""))

def test_subword_infix():
    assert subword("a", "a")
    assert not subword("a", "bbb")
    assert subword("b", "bbb")
    assert subword("a", "bab")

def test_subword_scattered():
    assert subword("ab", "aaabbb")
    assert not subword("ab", "bbbaaa")
    assert subword("aaaa","aaaab")
    assert subword("aaaa","baaaa")


def test_prefix_empty():
    assert prefix("", "")
    assert prefix("", "a")
    assert prefix("", "aba")
    assert not prefix("a", "")
    assert not prefix("aba", "")


def test_repr_word():
    assert repr_word("") == ""
    assert repr_word(["a", "b", "a"]) == "aba"
    assert repr_word(()) == ""
    assert repr_word(("a", "b", "a")) == "aba"

def test_repr_tikz():
    assert repr_tikz("") == "epsilon"
    assert repr_tikz("aba") == "aba"
    assert repr_tikz("ab") == repr_word("ab")

def test_repr_math():
    assert repr_math("") == "$\\varepsilon$"
    assert repr_math("aba") == "aba"
    assert repr_math("ab") == repr_word("ab")


def test_print_power():
    assert print_power("a", 2) == "{a^2}"
    assert print_power("a", 1) == "a"
    assert print_power("a", 0) == ""


def test_compress_word():
    assert compress_word("a") == "a"
    assert compress_word("aaa") == "{a^3}"
    assert compress_word("ab") == "ab"
    assert compress_word("abab") == "abab"
    assert compress_word("caabbc") == "c{a^2}{b^2}c"

def test_infix_encoding():
    nodes, edges = generate_figure(6, subword)
    nodes, edges = encode_in_infix(nodes, edges)

    for n in nodes.values():
        assert n.get("infix_enc", None) is not None
        assert n.get("item_num",  None) is not None
        assert n.get("layer_num", None) is not None

    for e in edges:
        u, v = e["from"], e["to"]
        assert infix(nodes[u]["infix_enc"], nodes[v]["infix_enc"])

    for u in nodes.values():
        for v in nodes.values():
            if u["layer_num"] + 1 == v["layer_num"]:
                u_leq_v = any(e["to"] == v["word"] for e in edges if e["from"] == u["word"])
                u_infleq_v = infix(u["infix_enc"], v["infix_enc"])
                assert u_infleq_v == u_leq_v

    
