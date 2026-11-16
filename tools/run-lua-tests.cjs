const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
process.chdir(path.resolve(__dirname,'..'));
for(const file of process.argv.slice(2)){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 lua.lua_pushcfunction(L,L=>{
  const file=to_jsstring(lua.lua_tostring(L,1)),source=to_luastring(fs.readFileSync(file,'utf8'));
  if(lauxlib.luaL_loadbuffer(L,source,source.length,to_luastring('@'+file))!==lua.LUA_OK)return lua.lua_error(L);
  return 1;
 });lua.lua_setglobal(L,to_luastring('loadfile'));
 if(lauxlib.luaL_dostring(L,to_luastring("unpack=table.unpack; assert(loadfile('"+file+"'))()"))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
 lua.lua_close(L);
}
