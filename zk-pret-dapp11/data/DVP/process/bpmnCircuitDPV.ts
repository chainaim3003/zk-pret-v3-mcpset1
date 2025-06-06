import { Bool, Field, UInt8 } from 'o1js';


// Command used: 'abc(edf|def|efd)gh(jklm(opqr(ty|su(vw|xy))|nu(vw|xy))|iu(vw|xy))' '--functionName' 'verifyProcess' '--filePath' './src/bpmnCircuitDPV.ts'
export function verifyProcessDVP(input: UInt8[]) {
	const num_bytes = input.length;
	let states: Bool[][] = Array.from({ length: num_bytes + 1 }, () => []);
	let state_changed: Bool[] = Array.from({ length: num_bytes }, () => Bool(false));
	
	states[0][0] = Bool(true);
	for (let i = 1; i < 24; i++) {
		states[0][i] = Bool(false);
	}
	
	for (let i = 0; i < num_bytes; i++) {
		const eq0 = input[i].value.equals(117);
		const and0 = states[i][8].and(eq0);
		states[i+1][1] = and0;
		state_changed[i] = state_changed[i].or(states[i+1][1]);
		const eq1 = input[i].value.equals(112);
		const and1 = states[i][23].and(eq1);
		states[i+1][2] = and1;
		state_changed[i] = state_changed[i].or(states[i+1][2]);
		const eq2 = input[i].value.equals(118);
		const and2 = states[i][1].and(eq2);
		states[i+1][3] = and2;
		state_changed[i] = state_changed[i].or(states[i+1][3]);
		const eq3 = input[i].value.equals(120);
		const and3 = states[i][1].and(eq3);
		const eq4 = input[i].value.equals(116);
		const and4 = states[i][7].and(eq4);
		let multi_or0 = Bool(false);
		multi_or0 = multi_or0.or(and3);
		multi_or0 = multi_or0.or(and4);
		states[i+1][4] = multi_or0;
		state_changed[i] = state_changed[i].or(states[i+1][4]);
		const eq5 = input[i].value.equals(113);
		const and5 = states[i][2].and(eq5);
		states[i+1][5] = and5;
		state_changed[i] = state_changed[i].or(states[i+1][5]);
		const eq6 = input[i].value.equals(119);
		const and6 = states[i][3].and(eq6);
		const eq7 = input[i].value.equals(121);
		const and7 = states[i][4].and(eq7);
		let multi_or1 = Bool(false);
		multi_or1 = multi_or1.or(and6);
		multi_or1 = multi_or1.or(and7);
		states[i+1][6] = multi_or1;
		state_changed[i] = state_changed[i].or(states[i+1][6]);
		const eq8 = input[i].value.equals(114);
		const and8 = states[i][5].and(eq8);
		states[i+1][7] = and8;
		state_changed[i] = state_changed[i].or(states[i+1][7]);
		const eq9 = input[i].value.equals(115);
		const and9 = states[i][7].and(eq9);
		const eq10 = input[i].value.equals(105);
		const and10 = states[i][18].and(eq10);
		const eq11 = input[i].value.equals(110);
		const and11 = states[i][22].and(eq11);
		let multi_or2 = Bool(false);
		multi_or2 = multi_or2.or(and9);
		multi_or2 = multi_or2.or(and10);
		multi_or2 = multi_or2.or(and11);
		states[i+1][8] = multi_or2;
		state_changed[i] = state_changed[i].or(states[i+1][8]);
		const eq12 = input[i].value.equals(97);
		const and12 = states[i][0].and(eq12);
		states[i+1][9] = and12;
		state_changed[i] = state_changed[i].or(states[i+1][9]);
		const eq13 = input[i].value.equals(98);
		const and13 = states[i][9].and(eq13);
		states[i+1][10] = and13;
		state_changed[i] = state_changed[i].or(states[i+1][10]);
		const eq14 = input[i].value.equals(99);
		const and14 = states[i][10].and(eq14);
		states[i+1][11] = and14;
		state_changed[i] = state_changed[i].or(states[i+1][11]);
		const eq15 = input[i].value.equals(100);
		const and15 = states[i][11].and(eq15);
		states[i+1][12] = and15;
		state_changed[i] = state_changed[i].or(states[i+1][12]);
		const eq16 = input[i].value.equals(101);
		const and16 = states[i][11].and(eq16);
		states[i+1][13] = and16;
		state_changed[i] = state_changed[i].or(states[i+1][13]);
		const and17 = states[i][12].and(eq16);
		const and18 = states[i][13].and(eq15);
		let multi_or3 = Bool(false);
		multi_or3 = multi_or3.or(and17);
		multi_or3 = multi_or3.or(and18);
		states[i+1][14] = multi_or3;
		state_changed[i] = state_changed[i].or(states[i+1][14]);
		const eq17 = input[i].value.equals(102);
		const and19 = states[i][13].and(eq17);
		states[i+1][15] = and19;
		state_changed[i] = state_changed[i].or(states[i+1][15]);
		const and20 = states[i][14].and(eq17);
		const and21 = states[i][15].and(eq15);
		let multi_or4 = Bool(false);
		multi_or4 = multi_or4.or(and20);
		multi_or4 = multi_or4.or(and21);
		states[i+1][16] = multi_or4;
		state_changed[i] = state_changed[i].or(states[i+1][16]);
		const eq18 = input[i].value.equals(103);
		const and22 = states[i][16].and(eq18);
		states[i+1][17] = and22;
		state_changed[i] = state_changed[i].or(states[i+1][17]);
		const eq19 = input[i].value.equals(104);
		const and23 = states[i][17].and(eq19);
		states[i+1][18] = and23;
		state_changed[i] = state_changed[i].or(states[i+1][18]);
		const eq20 = input[i].value.equals(106);
		const and24 = states[i][18].and(eq20);
		states[i+1][19] = and24;
		state_changed[i] = state_changed[i].or(states[i+1][19]);
		const eq21 = input[i].value.equals(107);
		const and25 = states[i][19].and(eq21);
		states[i+1][20] = and25;
		state_changed[i] = state_changed[i].or(states[i+1][20]);
		const eq22 = input[i].value.equals(108);
		const and26 = states[i][20].and(eq22);
		states[i+1][21] = and26;
		state_changed[i] = state_changed[i].or(states[i+1][21]);
		const eq23 = input[i].value.equals(109);
		const and27 = states[i][21].and(eq23);
		states[i+1][22] = and27;
		state_changed[i] = state_changed[i].or(states[i+1][22]);
		const eq24 = input[i].value.equals(111);
		const and28 = states[i][22].and(eq24);
		states[i+1][23] = and28;
		state_changed[i] = state_changed[i].or(states[i+1][23]);
		states[i+1][0] = state_changed[i].not();
	}
	
	let final_state_result = Bool(false);
	for (let i = 0; i <= num_bytes; i++) {
		final_state_result = final_state_result.or(states[i][6]);
	}
	const out = final_state_result;

	return out;
}
