const fs = require('node:fs');
const assert = require('node:assert/strict');
for (const [name, baseline] of [['Hexbound', 461], ['Soulbound', 473]]) {
  const layers = ['', 'Emission', 'Bloom'].map(suffix => fs.readFileSync(`Media/${name}${suffix}.tga`));
  for (const data of layers) {
    assert.equal(data.length, 18 + 512 * 512 * 4);
    assert.equal(data[2], 2);
    assert.equal(data[16], 32);
    assert.equal(data[17], 40);
    assert.equal(data.readUInt16LE(12), 512);
    assert.equal(data.readUInt16LE(14), 512);
  }
  const [base, core, bloom] = layers;
  let corePixels = 0, haloPixels = 0, bottom = -1, clear = 0;
  let eyes = 0;
  for (let y = 0; y < 512; y++) {
    let occupied = 0;
    for (let x = 0; x < 512; x++) {
      const p = 18 + (y * 512 + x) * 4;
      if (base[p + 3] >= 200) occupied++;
      if (base[p + 3] === 0) clear++;
      if (core[p + 3]) {
        assert(base[p + 3] && base[p + 1] - base[p + 2] > 12 && base[p + 1] - base[p] > 25,
          name + ' emission must align with painted green');
        corePixels++;
        if (name === 'Hexbound' && x > 370 && x < 440 && y > 170 && y < 225) eyes++;
      }
      if (bloom[p + 3] && !core[p + 3]) haloPixels++;
    }
    if (occupied >= 6) bottom = y;
  }
  assert.equal(bottom, baseline);
  assert(clear > 1000 && corePixels > 500 && haloPixels > 500);
  if (name === 'Hexbound') assert(eyes > 5, 'Green eye emission missing');
}
for (const name of ['SoulboundCrystal', 'SoulboundCrystalEmission']) {
  const data = fs.readFileSync(`Media/${name}.blp`);
  assert.equal(data.toString('ascii', 0, 4), 'BLP2');
  assert.equal(data[8], 3);
  assert.equal(data[9], 8);
  assert.equal(data[10], 2);
  assert.equal(data[11], 1);
  assert.equal(data.readUInt32LE(12), 256);
  assert.equal(data.readUInt32LE(16), 256);
  for (let level = 0; level < 9; level++) {
    const offset = data.readUInt32LE(20 + level * 4);
    const length = data.readUInt32LE(84 + level * 4);
    assert.equal(length, Math.pow(256 >> level, 2) * 4);
    assert(offset + length <= data.length);
  }
}
console.log('Warlock media PASS: green and eye registration, separate bloom, measured baselines, transparent bases and complete crystal mipmaps');
