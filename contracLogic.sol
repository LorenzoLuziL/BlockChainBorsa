// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./contractMemory.sol";
contract contractLogic is contractMemory{
//function to set the activity in the composition case 
//for the selection case I already have all the data so it is useless
    function setCompActivity(Activity memory act,bytes32 hashInstance) public {
     //   require(activities[act.id].id==act.id,"id Activity");
        require(checkKeyParicipants(act.initiator,hashInstance),"key initiator");
        require(checkKeyParicipants(act.target,hashInstance),"key target");
   //     require(act.messageIn==messages[act.messageIn].id,"message in");
   //     require(act.messageOut==messages[act.messageOut].id,"message out");
        instancies[hashInstance].activities[act.id]=act;
    }
//function to set the message in the composition case 
    function setCompMessage(Message memory _message,bytes32 hashInstance) public {
   //     require(messages[_message.id].id==_message.id,"id message");
        require(checkKeyMessage(_message.mappingKey,hashInstance),"key mapping");
     //   require(_message.idActivity==activities[_message.idActivity].id,"id activity message");
     //   require(checkAddressParticipants(activities[_message.idActivity].initiator,_message.sourceParticipant),"address initiator");
       // require(checkAddressParticipants(activities[_message.idActivity].target,_message.targetParticipant),"address target");
    //check the attributed selected in the case of compoxsition
      /**  for(uint i=0;i<_message.selectedAttr.length;i++){
            require(checkAttribute(_message.mappingKey,_message.selectedAttr[i]),"attribute");
        }
        require(!messages[_message.id].executed,"already executed");**/
        instancies[hashInstance].messages[_message.id]=_message;
    }

    function checkKeyParicipants(bytes32 key,bytes32 hashInstance)private view returns(bool){
        return instancies[hashInstance].participants[key].length>0;
    }


//funzione che mi controlla se un indirizzo è presente nella lista di indirizzo fornita all'inizio del generazione del contratto
//per togliere il for esterno potrei pensare di passare la key del mapping 
    function checkAddressParticipants(bytes32 key,address participant,bytes32 hashInstance) private view returns(bool){
            address [] memory temp=instancies[hashInstance].participants[key];
            for (uint j=0;j<temp.length;j++){
                if(temp[j]==participant){
                    return true;
                }
            }
        return false;
    }

//controllo se per quel messageso ci sono degli attributi inseriti 
//se non ci sono attributi significa che si cerca di utilizzare un messageso inserito durante la fase di running 
    function checkKeyMessage(bytes32 key,bytes32 hashInstance) public view returns(bool){
        return instancies[hashInstance].messageAttributes[key].length>0;
    }

//controllo se quell'attributo è presente in uno specifico mapping 
    function checkAttribute(bytes32 key,bytes32 attribute,bytes32 hashInstance)private view returns(bool){
        bytes32 [] memory temp=instancies[hashInstance].messageAttributes[key];
        for (uint i=0;i<temp.length;i++){
            if(temp[i]==attribute){
                return true;
            }
        }
        return false;
    }

//Check if i can execute that message 
    function checkTheExecution(bytes32 idMessage,bytes32 hashInstance) private returns (bool){
        Activity memory temp=instancies[hashInstance].activities[instancies[hashInstance].messages[idMessage].idActivity];
        //set the message executed to true
        if(temp.messageIn==idMessage){
            if(instancies[hashInstance].controlFlowElementList[temp.idInElement].id!=bytes32(0) && instancies[hashInstance].controlFlowElementList[temp.idInElement].elementType==ElementType.START){
                    instancies[hashInstance].messages[idMessage].executed=true;
                    instancies[hashInstance].controlFlowElementList[temp.idInElement].executed=true;
                    if(instancies[hashInstance].activities[temp.id].messageOut==bytes32(0)){
                        instancies[hashInstance].activities[temp.id].executed=true;
                    }
                    return true; 
            }else if(instancies[hashInstance].activities[temp.idInElement].id!=bytes32(0) && instancies[hashInstance].activities[temp.idInElement].executed){
                    instancies[hashInstance].messages[idMessage].executed=true;
                    if(instancies[hashInstance].activities[temp.id].messageOut==bytes32(0)){
                        instancies[hashInstance].activities[temp.id].executed=true;
                    }
                    return true;
            }else  if(instancies[hashInstance].controlFlowElementList[temp.idInElement].id!=bytes32(0) && checkForGatewayCondition(temp.idInElement,temp.id,hashInstance)){
                    instancies[hashInstance].controlFlowElementList[temp.idInElement].executed=true;
                    instancies[hashInstance].messages[idMessage].executed=true;
                    if(instancies[hashInstance].activities[temp.id].messageOut==bytes32(0)){
                        instancies[hashInstance].activities[temp.id].executed=true;
                    }
                    return true;
                
            }
        }
        //set the message executed to true and the activity to true;
        if(temp.messageOut==idMessage && instancies[hashInstance].messages[temp.messageIn].executed){
            instancies[hashInstance].messages[idMessage].executed=true;
            instancies[hashInstance].activities[instancies[hashInstance].messages[idMessage].idActivity].executed=true;
            return true;
        }
        require(1==0,"esco da 1");
        return false;
    }

function setActivityToFalse(bytes32 idActivity,bytes32 hashInstance) private {
        instancies[hashInstance].activities[idActivity].executed=false;
        instancies[hashInstance].activities[idActivity].tempState=true;
        instancies[hashInstance].messages[instancies[hashInstance].activities[idActivity].messageIn].executed=false;
        instancies[hashInstance].messages[instancies[hashInstance].activities[idActivity].messageIn].tempState=true;
        if(instancies[hashInstance].messages[instancies[hashInstance].activities[idActivity].messageOut].id!=bytes32(0)){
            instancies[hashInstance].messages[instancies[hashInstance].activities[idActivity].messageOut].executed=false;
            instancies[hashInstance].messages[instancies[hashInstance].activities[idActivity].messageOut].tempState=true;
        }
}
function checkNextElement(bytes32 idElement,bytes32 hashInstance) private {
    // Check if the element is an activity
    if (instancies[hashInstance].activities[idElement].id != bytes32(0)) {
        setActivityToFalse(idElement,hashInstance);
        return;
    }
    // Check if the element is a control flow element and not yet executed
    //ControlFlowElement storage element = controlFlowElementList[idElement];
    if (instancies[hashInstance].controlFlowElementList[idElement].id != bytes32(0) ) {
        // Evaluate the gateway condition and update execution status
        instancies[hashInstance].controlFlowElementList[idElement].executed = checkForNextGatewayCondition(idElement,hashInstance);
        // Update the outgoing activities based on the execution status
        if(checkForNextGatewayCondition(idElement,hashInstance) && instancies[hashInstance].controlFlowElementList[idElement].elementType!=ElementType.EX_SPLIT ){
            for (uint i = 0; i < instancies[hashInstance].controlFlowElementList[idElement].outgoingActivity.length; i++) {
                checkNextElement(instancies[hashInstance].controlFlowElementList[idElement].outgoingActivity[i],hashInstance);
                // bytes32 outgoingId = controlFlowElementList[idElement].outgoingActivity[i];
                //controlFlowElementList[outgoingId].executed = checkForNextGatewayCondition(outgoingId);
            }
        }
        return;
    }
}

function checkForNextGatewayCondition(bytes32 _idInElement,bytes32 hashInstance) private returns (bool) {
    ControlFlowElement storage gateway = instancies[hashInstance].controlFlowElementList[_idInElement];

    // Handle the simple cases first: EX_JOIN, PAR_SPLIT, EVENT_BASED
    if (
        gateway.elementType == ElementType.EX_JOIN || 
        gateway.elementType == ElementType.PAR_SPLIT || 
        gateway.elementType == ElementType.EVENT_BASED ||
        gateway.elementType == ElementType.TEMP || gateway.elementType == ElementType.END 
    ){
        return true;
    }
    // Handle EX_SPLIT
    if (gateway.elementType == ElementType.EX_SPLIT) {
        for (uint i = 0; i < gateway.outgoingActivity.length; i++) {
            bytes32 outgoingId = gateway.outgoingActivity[i];
            if (instancies[hashInstance].controlFlowElementList[outgoingId].id != bytes32(0)) {
                instancies[hashInstance].controlFlowElementList[outgoingId].executed = checkEdgesConditionOnlyId(outgoingId,hashInstance);
                if(checkEdgesConditionOnlyId(outgoingId,hashInstance)){
                    checkNextElement(outgoingId,hashInstance);
                }
            }
            if(instancies[hashInstance].activities[outgoingId].id !=bytes32(0) && checkEdgesConditionOnlyId(outgoingId,hashInstance)){
                setActivityToFalse(outgoingId,hashInstance);
            }
        }
        return true;
    }

    // Handle PAR_JOIN
    if (gateway.elementType == ElementType.PAR_JOIN) {
        for (uint i = 0; i < gateway.incomingActivity.length; i++) {
            bytes32 incomingId = gateway.incomingActivity[i];
            if (instancies[hashInstance].activities[incomingId].id != bytes32(0) && !instancies[hashInstance].activities[incomingId].executed) {
                return false;
            }
        }
        return true;
    }

    return false;
}

//Che the condition for different gateway
    function checkForGatewayCondition(bytes32 _idInElement,bytes32 currentActivity,bytes32 hashInstance) private  returns(bool){
        //Check the condition for an split exclusie gateway
        //It have to controll the previous task and the condition on the edge 
        ControlFlowElement memory gateway=instancies[hashInstance].controlFlowElementList[_idInElement];
        if(gateway.elementType==ElementType.EX_SPLIT ){
            //this is to check the previous task
            if(instancies[hashInstance].activities[gateway.incomingActivity[0]].id!=bytes32(0)){
                if(instancies[hashInstance].activities[gateway.incomingActivity[0]].executed){
                    //this is to check the condition on the edge
                    for(uint i=0;i<gateway.outgoingActivity.length;i++){
                        if(instancies[hashInstance].activities[gateway.outgoingActivity[i]].executed){
                            return false;
                        }
                    }
                    if(checkEdgesConditionOnlyId(currentActivity,hashInstance)){
                        return true;
                    }
                }
                return false; 
            }
        }
        //check if the element is an exclusive gateway 
        if(gateway.elementType==ElementType.EX_JOIN ){
            //the condition is that one of the previous task have to be executed
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(instancies[hashInstance].activities[gateway.incomingActivity[i]].id==gateway.incomingActivity[i]){
                    if(instancies[hashInstance].activities[gateway.incomingActivity[i]].executed){
                        return true;
                    }
                }
                
            }
            return false;
        }
        //check if the element is a parallel split gateway
        //the only condition is that the previous task have to be executed
        if(gateway.elementType==ElementType.PAR_SPLIT ){
            if(instancies[hashInstance].activities[gateway.incomingActivity[0]].id!=bytes32(0) && instancies[hashInstance].activities[gateway.incomingActivity[0]].executed){
                return true;
            }else if(instancies[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].id!=bytes32(0) && instancies[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].executed){
                return true;
            }
            require (1==0,"uscito dal if parSplit");
            return false;
        }
        //check if the element is a parallel join gateway
        //check if all the previous task are executed
        if(gateway.elementType==ElementType.PAR_JOIN ){
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(instancies[hashInstance].activities[gateway.incomingActivity[i]].id!=bytes32(0)){
                    if(!instancies[hashInstance].activities[gateway.incomingActivity[i]].executed){
                        return false;
                    }
                }
            }
            return true;
        }

        //check if the element is a event based 
        //al the outgoing has to be not executed 
        if(gateway.elementType==ElementType.EVENT_BASED){
            if(instancies[hashInstance].activities[gateway.incomingActivity[0]].executed || instancies[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].executed){
                for(uint i=0;i<gateway.outgoingActivity.length;i++){
                    if(instancies[hashInstance].activities[gateway.outgoingActivity[i]].executed){
                        return false;
                    }else{
                        instancies[hashInstance].activities[gateway.outgoingActivity[i]].executed=false;
                        instancies[hashInstance].activities[gateway.outgoingActivity[i]].tempState=false;
                        instancies[hashInstance].messages[instancies[hashInstance].activities[gateway.outgoingActivity[i]].messageIn].executed=false;
                        instancies[hashInstance].messages[instancies[hashInstance].activities[gateway.outgoingActivity[i]].messageIn].tempState=false;
                        if(instancies[hashInstance].messages[instancies[hashInstance].activities[gateway.outgoingActivity[i]].messageOut].id!=bytes32(0)){
                            instancies[hashInstance].messages[instancies[hashInstance].activities[gateway.outgoingActivity[i]].messageOut].executed=false;
                            instancies[hashInstance].messages[instancies[hashInstance].activities[gateway.outgoingActivity[i]].messageOut].tempState=false;
                        }
                    }
                }
                return true;
            }
        }
        if(gateway.elementType==ElementType.TEMP){
            return true;
        }
        require (1==0,"uscito dal if generale");
        return false;
    }



    function checkEdgesConditionOnlyId(bytes32 currentActivity,bytes32 hashInstance) private view returns (bool){
        //get the edge from the gateway to the task where I execute the message
        EdgeCondition[] memory conditionType=instancies[hashInstance].edgeConditionMapping[currentActivity];
        for (uint i=0;i<conditionType.length;i++){
        //switch case to perform the controll of the attribute and a value
            if(conditionType[i].condition==ConditionType.EQUAL){
                return equal(conditionType[i].attribute,conditionType[i].comparisonValue,hashInstance);
            }
            
        }
        return false;
    }
//quando eseguo un messageso eseguo questa funzione per assegnare un valore ai vari attributi 
    function insertIntoMap(bytes32 [] memory attributi, bytes32[] memory value,bytes32 hashInstance) private {
        for(uint i=0;i<attributi.length;i++){
            instancies[hashInstance].attributeValue[attributi[i]]=value[i];
        }
    }

//execute the message in the composition case
//It has to set all the information reguarding the activity all the information for the message and 
//It has to check for the execution
    function executeCompMessage(Activity memory _activity,Message memory _message,
    ControlFlowElement[] memory currentcontrolFlowElement,
    bytes32 [] memory attributi, bytes32[] memory value,Activity[] memory activityList,
    ControlFlowElement[] memory controlFlowElement,EdgeCondition[] memory edgeCondition,
    Message[] memory messageList, bytes32 hashInstance) public {
        require(instancies[hashInstance].messages[_message.id].executed==false,"already executed");
        
        setCompActivity(_activity,hashInstance);
        setCompMessage(_message,hashInstance);
        setCurrentControlFlow(currentcontrolFlowElement,hashInstance);
        setDiff(activityList,controlFlowElement,edgeCondition,messageList,hashInstance);
        require(checkTheExecution(_message.id,hashInstance),"errore nella validazione dell'esecuzione");
        insertIntoMap(attributi, value,hashInstance);
    if(_activity.idOutElement!=bytes32(0)){
        if(instancies[hashInstance].activities[_activity.id].messageIn==_message.id && instancies[hashInstance].activities[_activity.id].messageOut==bytes32(0)){
            checkNextElement(_activity.idOutElement,hashInstance);
        }else if(instancies[hashInstance].activities[_activity.id].messageOut==_message.id){
            checkNextElement(_activity.idOutElement,hashInstance);
        }
    }
        emit functionDone("Messagge executed");
    }
    function setCurrentControlFlow (ControlFlowElement[] memory controlFlowElement,bytes32 hashIdInstance) private{
         for(uint i=0;i<controlFlowElement.length;i++){
            instancies[hashIdInstance].controlFlowElementList[controlFlowElement[i].id]=controlFlowElement[i];
        }
    }
    function equal(bytes32 attribute,bytes32 value,bytes32 hashInstance)private view returns (bool){
        return instancies[hashInstance].attributeValue[attribute]==value;
    }
    function setDiff(Activity [] memory activities,
        ControlFlowElement[] memory allControlFlowElement,EdgeCondition[] memory edgeCondition,
        Message [] memory allMessages
        ,bytes32 hashIdInstance) internal {
        for(uint i=0;i<activities.length;i++){
            instancies[hashIdInstance].activities[activities[i].id]=activities[i];
        }
        for(uint i=0;i<allMessages.length;i++){
            instancies[hashIdInstance].messages[allMessages[i].id]=allMessages[i];
        }
        for(uint i=0;i<allControlFlowElement.length;i++){
            instancies[hashIdInstance].controlFlowElementList[allControlFlowElement[i].id]=allControlFlowElement[i];
        }
         for(uint i=0;i<edgeCondition.length;i++){
            instancies[hashIdInstance].edgeConditionMapping[edgeCondition[i].idActivity].push(edgeCondition[i]);
        }
    } 
}