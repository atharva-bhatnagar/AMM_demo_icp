import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";

actor {

  private var balanceTokenA=0;
  private var balanceTokenB=0;
  private var lpTokenSupply=0;

  type TokenType={
    #a;
    #b;
  };
  type Pool={
    tokenA:Nat;
    tokenB:Nat;
    lpTokenSupply:Nat;
  };
  type TokenReturned={
    tokenType:TokenType;
    value:Nat;
  };
  type LiquidityRemoveResult={
    receivedTokenA:Nat;
    receivedTokenB:Nat;
  };

  public func addLiquidity(tokenA:Nat,tokenB:Nat):async Bool{
    if(tokenA==0 or tokenB==0){
      Debug.trap("Cannot send 0 amount for either of the tokens");
    };
    if(balanceTokenA * tokenB == balanceTokenB * tokenA){
      balanceTokenA:=balanceTokenA+tokenA;
      balanceTokenB:=balanceTokenB+tokenB;
      let newLpTokens=Float.sqrt(Float.fromInt(tokenA * tokenB));
      lpTokenSupply:= lpTokenSupply + Int.abs(Float.toInt(newLpTokens));
      return true
    }else{
      Debug.trap("Tokens cannot be added due to inproportional values");
    };
  };

  public query func getPoolState():async Pool{
    return {
      tokenA=balanceTokenA;
      tokenB=balanceTokenB;
      lpTokenSupply=lpTokenSupply;
    }
  };

  public func removeLiquidity(lpTokens:Nat):async LiquidityRemoveResult{
    if(lpTokens==0){
      Debug.trap("Invalid lptoken input");
    };
    if(lpTokens > lpTokenSupply){
      Debug.trap("Insufficient liquidity");
    };
    let returnedTokenA = balanceTokenA * lpTokens / lpTokenSupply;
    let returnedTokenB = balanceTokenB * lpTokens / lpTokenSupply;
    balanceTokenA := balanceTokenA-returnedTokenA;
    balanceTokenB := balanceTokenB-returnedTokenB;
    lpTokenSupply := lpTokenSupply-lpTokens;
    return {
      receivedTokenA=returnedTokenA;
      receivedTokenB=returnedTokenB;
    }
  };

  public func swap(tokenIn:TokenType,amountIn:Nat):async TokenReturned{
    if(amountIn==0){
      Debug.trap("Cannot swap 0 with anything");
    };
    switch(tokenIn){
      case(#a){
        let newBalanceA=balanceTokenA+amountIn;
        let amountReturned = balanceTokenB*amountIn/newBalanceA;
        if(amountReturned > balanceTokenB){
          Debug.trap("Insufficient liquidity");
        };
        balanceTokenA := balanceTokenA + amountIn;
        balanceTokenB := balanceTokenB - amountReturned;
        return {
          tokenType=#b;
          value=amountReturned;
        }
      };
      case(#b){
        let amountReturned = (balanceTokenA*amountIn)/(balanceTokenB+amountIn);
        if(amountReturned > balanceTokenA){
          Debug.trap("Insufficient liquidity");
        };
        balanceTokenB := balanceTokenB + amountIn;
        balanceTokenA := balanceTokenA - amountReturned;
        return {
          tokenType=#a;
          value=amountReturned;
      };
    };
  };

  };
};
