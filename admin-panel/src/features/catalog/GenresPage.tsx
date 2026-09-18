import SimpleCrudList from "../../shared/SimpleCrudList";
import { createGenre, deleteGenre, fetchGenres, renameGenre } from "./api";

export default function GenresPage() {
  return (
    <SimpleCrudList
      title="Жанры"
      fetchItems={fetchGenres}
      createItem={createGenre}
      renameItem={renameGenre}
      deleteItem={deleteGenre}
    />
  );
}
