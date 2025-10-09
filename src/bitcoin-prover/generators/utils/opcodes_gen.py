PATH = "./crates/script/src/generated.nr"


def generate(sizes: set, taproot: bool = False):

    hash160 = {e for e in sizes if e[0] == 169}
    hash256 = {e for e in sizes if e[0] == 170}
    ripemd160 = {e for e in sizes if e[0] == 166}
    sha256 = {e for e in sizes if e[0] == 168}
    sha1 = {e for e in sizes if e[0] == 167}
    checksig = any(e[0] == 172 or e[0] == 173 for e in sizes)
    mulsig = {e for e in sizes if e[0] == 174 or e[0] == 175}
    pushbytes = {e for e in sizes if e[0] >= 1 and e[0] <= 75}
    pushdata1 = {e for e in sizes if e[0] == 76}
    pushdata2 = {e for e in sizes if e[0] == 77}
    pushdata4 = {e for e in sizes if e[0] == 78}

    hash160ifs = "\n".join(
        f"""    if len == {e[1]} {{
        stack.op_hash160::<{e[1]}>();
    }}""" for e in hash160
    )

    hash256ifs = "\n".join(
        f"""    if len == {e[1]} {{
        stack.op_hash256::<{e[1]}>();
    }}""" for e in hash256
    )

    ripemd160ifs = "\n".join(
        f"""    if len == {e[1]} {{
        stack.op_ripemd160::<{e[1]}>();
    }}""" for e in ripemd160
    )

    sha256ifs = "\n".join(
        f"""    if len == {e[1]} {{
        stack.op_sha256::<{e[1]}>();
    }}""" for e in sha256
    )

    sha1ifs = "\n".join(
        f"""    if len == {e[1]} {{
        stack.op_sha1::<{e[1]}>();
    }}""" for e in sha1
    )

    if not taproot:
        checksigif = ("""stack
        .op_checksig::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
            address,
            verify,
            sigadd,
        );""") if checksig else ""
    else:
        checksigif = (
            """stack.op_checksig_p2tr::<UTXOS_LEN, CURRENT_INPUT_COUNT>(utxo_data, verify, sigadd, Option::none(), leaf_script_hash);""") if checksig else ""

    mulsigifs = "\n".join(
        f"""    if (n == {e[2]}) & (m == {e[3]}) {{
        stack.op_checkmulsig::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE, {e[2]}, {e[3]}>(address, verify);
    }}""" for e in mulsig
    )

    pushbytesifs = "\n".join(
        f"""\tif len == {e[0]} {{
        let mut value = [0; {e[0]}];
        for i in 0..{e[0]} {{
            value[i] = script[cur_pos];
            cur_pos += 1;
        }}
        stack.push_bytes(value);
    }}""" for e in pushbytes
    )

    pushdata1ifs = "\n".join(
        f"""\tif len == {e[1]} {{
        let mut value = [0; {e[1]}];
        for i in 0..{e[1]} {{
            value[i] = script[cur_pos];
            cur_pos += 1;
        }}
        stack.push_bytes(value);
    }}""" for e in pushdata1
    )

    pushdata2ifs = "\n".join(
        f"""\tif len == {e[1]} {{
        let mut value = [0; {e[1]}];
        for i in 0..{e[1]} {{
            value[i] = script[cur_pos];
            cur_pos += 1;
        }}
        stack.push_bytes(value);
    }}""" for e in pushdata2
    )

    pushdata4ifs = "\n".join(
        f"""\tif len == {e[1]} {{
        let mut value = [0; {e[1]}];
        for i in 0..{e[1]} {{
            value[i] = script[cur_pos];
            cur_pos += 1;
        }}
        stack.push_bytes(value);
    }}""" for e in pushdata4
    )

    with open(PATH + ".template") as file:
        templateGenerated = file.read()

    generatedFile = templateGenerated.format(
        hash160=hash160ifs,
        hash256=hash256ifs,
        ripemd160=ripemd160ifs,
        sha256=sha256ifs,
        sha1=sha1ifs,
        checksig=checksigif,
        checkmulsig=mulsigifs,
        byshbytes=pushbytesifs,
        pushdata1=pushdata1ifs,
        pushdata2=pushdata2ifs,
        pushdata4=pushdata4ifs,
    )

    with open(PATH, 'w') as file:
        file.write(generatedFile)
