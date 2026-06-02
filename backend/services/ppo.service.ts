import axios from "axios";

export const getAIAction = async (state: any) => {
  const response = await axios.post(
    "http://localhost:8001/predictPPO",
    state
  );
  return response.data;
};
