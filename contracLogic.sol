// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./contractMemory.sol";
contract contractLogic is contractMemory{
//function to set the activity in the composition case 
//for the selection case I already have all the data so it is useless
    function setCompActivity(Activity memory act,uint256 hashInstance) public {
     //   require(attivita[act.id].id==act.id,"id Activity");
        require(checkKeyParicipants(act.initiator,hashInstance),"key initiator");
        require(checkKeyParicipants(act.target,hashInstance),"key target");
   //     require(act.messageIn==messaggi[act.messageIn].id,"message in");
   //     require(act.messageOut==messaggi[act.messageOut].id,"message out");
        singleIstanceToMemory[hashInstance].attivita[act.id]=act;
    }
//function to set the message in the composition case 
    function setCompMessage(Message memory _message,uint256 hashInstance) public {
   //     require(messaggi[_message.id].id==_message.id,"id message");
        require(checkKeyMessage(_message.mappingKey,hashInstance),"key mapping");
     //   require(_message.idActivity==attivita[_message.idActivity].id,"id activity message");
     //   require(checkAddressParticipants(attivita[_message.idActivity].initiator,_message.sourceParticipant),"address initiator");
       // require(checkAddressParticipants(attivita[_message.idActivity].target,_message.targetParticipant),"address target");
    //check the attributed selected in the case of composition
      /**  for(uint i=0;i<_message.selectedAttr.length;i++){
            require(checkAttribute(_message.mappingKey,_message.selectedAttr[i]),"attribute");
        }
        require(!messaggi[_message.id].executed,"already executed");**/
        singleIstanceToMemory[hashInstance].messaggi[_message.id]=_message;
    }

    function checkKeyParicipants(bytes32 key,uint256 hashInstance)private view returns(bool){
        return singleIstanceToMemory[hashInstance].participants[key].length>0;
    }

//funzione che mi controlla se un indirizzo è presente nella lista di indirizzo fornita all'inizio del generazione del contratto
//per togliere il for esterno potrei pensare di passare la key del mapping 
    function checkAddressParticipants(bytes32 key,address participant,uint256 hashInstance) private view returns(bool){
            address [] memory temp=singleIstanceToMemory[hashInstance].participants[key];
            for (uint j=0;j<temp.length;j++){
                if(temp[j]==participant){
                    return true;
                }
            }
        return false;
    }

//controllo se per quel messaggio ci sono degli attributi inseriti 
//se non ci sono attributi significa che si cerca di utilizzare un messaggio inserito durante la fase di running 
    function checkKeyMessage(bytes32 key,uint256 hashInstance) public view returns(bool){
        return singleIstanceToMemory[hashInstance].messageAttributes[key].length>0;
    }

//controllo se quell'attributo è presente in uno specifico mapping 
    function checkAttribute(bytes32 key,bytes32 attribute,uint256 hashInstance)private view returns(bool){
        bytes32 [] memory temp=singleIstanceToMemory[hashInstance].messageAttributes[key];
        for (uint i=0;i<temp.length;i++){
            if(temp[i]==attribute){
                return true;
            }
        }
        return false;
    }

//Check if i can execute that message 
    function checkTheExecution(bytes32 idMessage,uint256 hashInstance) private returns (bool){
        Activity memory temp=singleIstanceToMemory[hashInstance].attivita[singleIstanceToMemory[hashInstance].messaggi[idMessage].idActivity];
        //set the message executed to true
        if(temp.messageIn==idMessage){
            if(singleIstanceToMemory[hashInstance].attivita[temp.idInElement].executed){
                singleIstanceToMemory[hashInstance].messaggi[idMessage].executed=true;
                if(singleIstanceToMemory[hashInstance].attivita[temp.id].messageOut==bytes32(0)){
                    singleIstanceToMemory[hashInstance].attivita[temp.id].executed=true;
                }
                return true;
            }else if (singleIstanceToMemory[hashInstance].controlFlowElementList[temp.idInElement].id==temp.idInElement){
                if(singleIstanceToMemory[hashInstance].controlFlowElementList[temp.idInElement].tipo==ElementType.START){
                    singleIstanceToMemory[hashInstance].messaggi[idMessage].executed=true;
                    singleIstanceToMemory[hashInstance].controlFlowElementList[temp.idInElement].executed=true;
                    if(singleIstanceToMemory[hashInstance].attivita[temp.id].messageOut==bytes32(0)){
                        singleIstanceToMemory[hashInstance].attivita[temp.id].executed=true;
                    }
                    return true; 
                }else if(singleIstanceToMemory[hashInstance].controlFlowElementList[temp.idInElement].executed && checkForGatewayCondition(temp.idInElement,temp.id,hashInstance)){
                    singleIstanceToMemory[hashInstance].messaggi[idMessage].executed=true;
                    if(singleIstanceToMemory[hashInstance].attivita[temp.id].messageOut==bytes32(0)){
                        singleIstanceToMemory[hashInstance].attivita[temp.id].executed=true;
                    }
                    return true;
                }
                require(1==0,"esco da qui");
            }
        }
        //set the message executed to true and the activity to true;
        if(temp.messageOut==idMessage && singleIstanceToMemory[hashInstance].messaggi[temp.messageIn].executed){
            singleIstanceToMemory[hashInstance].messaggi[idMessage].executed=true;
            singleIstanceToMemory[hashInstance].attivita[singleIstanceToMemory[hashInstance].messaggi[idMessage].idActivity].executed=true;
            return true;
        }
        require(1==0,"esco da 1");
        return false;
    }

function setActivityToFalse(bytes32 idActivity,uint256 hashInstance) private {
        singleIstanceToMemory[hashInstance].attivita[idActivity].executed=false;
        singleIstanceToMemory[hashInstance].attivita[idActivity].tempState=true;
        singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[idActivity].messageIn].executed=false;
        singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[idActivity].messageIn].tempState=true;
        if(singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[idActivity].messageOut].id!=bytes32(0)){
            singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[idActivity].messageOut].executed=false;
            singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[idActivity].messageOut].tempState=true;
        }
}
function checkNextElement(bytes32 idElement,uint256 hashInstance) private {
    // Check if the element is an activity
    if (singleIstanceToMemory[hashInstance].attivita[idElement].id != bytes32(0)) {
        setActivityToFalse(idElement,hashInstance);
        return;
    }
    // Check if the element is a control flow element and not yet executed
    //ControlFlowElement storage element = controlFlowElementList[idElement];
    if (singleIstanceToMemory[hashInstance].controlFlowElementList[idElement].id != bytes32(0) ) {
        // Evaluate the gateway condition and update execution status
        singleIstanceToMemory[hashInstance].controlFlowElementList[idElement].executed = checkForNextGatewayCondition(idElement,hashInstance);
        // Update the outgoing activities based on the execution status
        if(checkForNextGatewayCondition(idElement,hashInstance) && singleIstanceToMemory[hashInstance].controlFlowElementList[idElement].tipo!=ElementType.EX_SPLIT ){
            for (uint i = 0; i < singleIstanceToMemory[hashInstance].controlFlowElementList[idElement].outgoingActivity.length; i++) {
                checkNextElement(singleIstanceToMemory[hashInstance].controlFlowElementList[idElement].outgoingActivity[i],hashInstance);
                // bytes32 outgoingId = controlFlowElementList[idElement].outgoingActivity[i];
                //controlFlowElementList[outgoingId].executed = checkForNextGatewayCondition(outgoingId);
            }
        }
        return;
    }
}

function checkForNextGatewayCondition(bytes32 _idInElement,uint256 hashInstance) private returns (bool) {
    ControlFlowElement storage gateway = singleIstanceToMemory[hashInstance].controlFlowElementList[_idInElement];

    // Handle the simple cases first: EX_JOIN, PAR_SPLIT, EVENT_BASED
    if (
        gateway.tipo == ElementType.EX_JOIN || 
        gateway.tipo == ElementType.PAR_SPLIT || 
        gateway.tipo == ElementType.EVENT_BASED ||
        gateway.tipo == ElementType.TEMP || gateway.tipo == ElementType.END 
    ){
        return true;
    }
    // Handle EX_SPLIT
    if (gateway.tipo == ElementType.EX_SPLIT) {
        for (uint i = 0; i < gateway.outgoingActivity.length; i++) {
            bytes32 outgoingId = gateway.outgoingActivity[i];
            if (singleIstanceToMemory[hashInstance].controlFlowElementList[outgoingId].id != bytes32(0)) {
                singleIstanceToMemory[hashInstance].controlFlowElementList[outgoingId].executed = checkEdgesConditionOnlyId(outgoingId,hashInstance);
                if(checkEdgesConditionOnlyId(outgoingId,hashInstance)){
                    checkNextElement(outgoingId,hashInstance);
                }
            }
            if(singleIstanceToMemory[hashInstance].attivita[outgoingId].id !=bytes32(0) && checkEdgesConditionOnlyId(outgoingId,hashInstance)){
                setActivityToFalse(outgoingId,hashInstance);
            }
        }
        return true;
    }

    // Handle PAR_JOIN
    if (gateway.tipo == ElementType.PAR_JOIN) {
        for (uint i = 0; i < gateway.incomingActivity.length; i++) {
            bytes32 incomingId = gateway.incomingActivity[i];
            if (singleIstanceToMemory[hashInstance].attivita[incomingId].id != bytes32(0) && !singleIstanceToMemory[hashInstance].attivita[incomingId].executed) {
                return false;
            }
        }
        return true;
    }

    return false;
}

//Che the condition for different gateway
    function checkForGatewayCondition(bytes32 _idInElement,bytes32 currentActivity,uint256 hashInstance) private  returns(bool){
        //Check the condition for an split exclusie gateway
        //It have to controll the previous task and the condition on the edge 
        ControlFlowElement memory gateway=singleIstanceToMemory[hashInstance].controlFlowElementList[_idInElement];
        if(gateway.tipo==ElementType.EX_SPLIT && gateway.executed){
            //this is to check the previous task
            if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[0]].id!=bytes32(0)){
                if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[0]].executed){
                    //this is to check the condition on the edge
                    for(uint i=0;i<gateway.outgoingActivity.length;i++){
                        if(singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].executed){
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
        if(gateway.tipo==ElementType.EX_JOIN && gateway.executed){
            //the condition is that one of the previous task have to be executed
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[i]].id==gateway.incomingActivity[i]){
                    if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[i]].executed){
                        return true;
                    }
                }
                
            }
            return false;
        }
        //check if the element is a parallel split gateway
        //the only condition is that the previous task have to be executed
        if(gateway.tipo==ElementType.PAR_SPLIT && gateway.executed){
            if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[0]].id!=bytes32(0) && singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[0]].executed){
                return true;
            }else if(singleIstanceToMemory[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].id!=bytes32(0) && singleIstanceToMemory[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].executed){
                return true;
            }
            require (1==0,"uscito dal if parSplit");
            return false;
        }
        //check if the element is a parallel join gateway
        //check if all the previous task are executed
        if(gateway.tipo==ElementType.PAR_JOIN && gateway.executed){
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[i]].id!=bytes32(0)){
                    if(!singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[i]].executed){
                        return false;
                    }
                }
            }
            return true;
        }

        //check if the element is a event based 
        //al the outgoing has to be not executed 
        if(gateway.tipo==ElementType.EVENT_BASED && gateway.executed){
            if(singleIstanceToMemory[hashInstance].attivita[gateway.incomingActivity[0]].executed || singleIstanceToMemory[hashInstance].controlFlowElementList[gateway.incomingActivity[0]].executed){
                for(uint i=0;i<gateway.outgoingActivity.length;i++){
                    if(singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].executed){
                        return false;
                    }else{
                        singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].executed=false;
                        singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].tempState=false;
                        singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].messageIn].executed=false;
                        singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].messageIn].tempState=false;
                        if(singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].messageOut].id!=bytes32(0)){
                            singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].messageOut].executed=false;
                            singleIstanceToMemory[hashInstance].messaggi[singleIstanceToMemory[hashInstance].attivita[gateway.outgoingActivity[i]].messageOut].tempState=false;
                        }
                    }
                }
                return true;
            }
        }
        if(gateway.tipo==ElementType.TEMP && gateway.executed){
            return true;
        }
        require (1==0,"uscito dal if generale");
        return false;
    }



    function checkEdgesConditionOnlyId(bytes32 currentActivity,uint256 hashInstance) private view returns (bool){
        //get the edge from the gateway to the task where I execute the message
        EdgeCondition[] memory conditionType=singleIstanceToMemory[hashInstance].edgeConditionMapping[currentActivity];
        for (uint i=0;i<conditionType.length;i++){
        //switch case to perform the controll of the attribute and a value
            if(conditionType[i].condition==ConditionType.EQUAL){
                return equal(conditionType[i].attribute,conditionType[i].comparisonValue,hashInstance);
            }
            
        }
        return false;
    }
//quando eseguo un messaggio eseguo questa funzione per assegnare un valore ai vari attributi 
    function insertIntoMap(bytes32 [] memory attributi, bytes32[] memory value,uint256 hashInstance) private {
        for(uint i=0;i<attributi.length;i++){
            singleIstanceToMemory[hashInstance].attributiValue[attributi[i]]=value[i];
        }
    }

//execute the message in the composition case
//It has to set all the information reguarding the activity all the information for the message and 
//It has to check for the execution
    function executeCompMessage(Activity memory _activity,Message memory _message,
    bytes32 [] memory attributi, bytes32[] memory value,ControlFlowElement[] memory _contolFlowElement,
    EdgeCondition[] memory someEdgeCondition,Activity[] memory nextActivities,
    Message[] memory newMessage,uint256 hashInstance) public {
        setCompActivity(_activity,hashInstance);
        setCompMessage(_message,hashInstance);
        setComControlFlowElement(_contolFlowElement,someEdgeCondition,hashInstance);
        require(checkTheExecution(_message.id,hashInstance),"errore nella validazione dell'esecuzione");
        Activity memory temp=singleIstanceToMemory[hashInstance].attivita[_activity.id];
        insertIntoMap(attributi, value,hashInstance);
        if(temp.messageIn==_message.id && temp.messageOut==bytes32(0)){
            checkNextElement(temp.idOutElement,hashInstance);
        }else if(temp.messageOut==_message.id){
            checkNextElement(temp.idOutElement,hashInstance);
        }
        emit functionDone("Messagge executed");
    }
//how to check the control flow element if i can add it to during the execution ??
    function setComControlFlowElement(ControlFlowElement[] memory _controlFlowElement,EdgeCondition[] memory _someEdgeCondition,uint256 hashInstance)private {
        for(uint i=0;i<_controlFlowElement.length;i++){
            singleIstanceToMemory[hashInstance].controlFlowElementList[_controlFlowElement[i].id]=_controlFlowElement[i];
        }
        for(uint i=0;i<_someEdgeCondition.length;i++){
            singleIstanceToMemory[hashInstance].edgeConditionMapping[_someEdgeCondition[i].idActivity].push(_someEdgeCondition[i]);
        }
    }
    function equal(bytes32 attribute,bytes32 value,uint256 hashInstance)private view returns (bool){
        return singleIstanceToMemory[hashInstance].attributiValue[attribute]==value;
    }

    function setNextActivities(Activity[] memory nextActivities,uint256 hashInstance) private{
        for(uint i=0;i<nextActivities.length;i++){
            singleIstanceToMemory[hashInstance].attivita[nextActivities[i].id]=nextActivities[i];
        }
        emit functionDone("Resources Loaded");
    }
    function setNewMessage(Message[] memory newMessage,uint256 hashInstance) private{
        for(uint i=0;i<newMessage.length;i++){
            singleIstanceToMemory[hashInstance].messaggi[newMessage[i].id]=newMessage[i];
        }
    }   
}